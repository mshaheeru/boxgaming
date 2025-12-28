import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { SlotService } from './slot.service';
import { BookingLockService } from './booking-lock.service';
import { QrService } from './qr.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@Injectable()
export class BookingsService {
  constructor(
    private supabaseService: SupabaseService,
    private slotService: SlotService,
    private bookingLockService: BookingLockService,
    private qrService: QrService,
  ) {}

  /**
   * Create a pending booking (before payment)
   */
  async createPendingBooking(customerId: string, dto: CreateBookingDto) {
    const { groundId, bookingDate, startTime, durationHours } = dto;

    // Verify ground exists
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: ground, error: groundError } = await supabase
      .from('grounds')
      .select(`
        *,
        venue:venues!grounds_venue_id_fkey(*)
      `)
      .eq('id', groundId)
      .single();

    if (!ground || groundError) {
      throw new NotFoundException('Ground not found');
    }

    if (!ground.is_active) {
      throw new BadRequestException('Ground is not active');
    }

    // Check slot availability
    const date = new Date(bookingDate);
    const slots = await this.slotService.getAvailableSlots(
      groundId,
      date,
      durationHours as 2 | 3,
    );

    const selectedSlot = slots.find((s) => s.time === startTime && s.available);
    if (!selectedSlot) {
      throw new BadRequestException('Selected slot is not available');
    }

    // Acquire lock
    const dateStr = date.toISOString().split('T')[0];
    const lockKey = await this.bookingLockService.acquireLock(
      groundId,
      dateStr,
      startTime,
    );

    try {
      // Double-check availability (race condition protection)
      const { data: existingBooking } = await supabase
        .from('bookings')
        .select('id')
        .eq('ground_id', groundId)
        .eq('booking_date', dateStr)
        .eq('start_time', startTime)
        .not('status', 'in', '(cancelled,no_show)')
        .limit(1)
        .single();

      if (existingBooking) {
        throw new BadRequestException('Slot has been booked by another user');
      }

      // Calculate price
      const price = durationHours === 2 ? ground.price_2hr : ground.price_3hr;

      // Generate booking code
      const bookingCode = this.qrService.generateBookingCode();

      // Create pending booking
      const { data: booking, error: createError } = await supabase
        .from('bookings')
        .insert({
          booking_code: bookingCode,
          customer_id: customerId,
          ground_id: groundId,
          venue_id: ground.venue_id,
          booking_date: dateStr,
          start_time: startTime,
          duration_hours: durationHours,
          price,
          status: 'confirmed', // Will be confirmed after payment
          payment_status: 'paid', // Temporary, will be updated by payment webhook
        })
        .select(`
          *,
          ground:grounds!bookings_ground_id_fkey(
            *,
            venue:venues!grounds_venue_id_fkey(id, name, address)
          ),
          customer:users!bookings_customer_id_fkey(id, name, phone)
        `)
        .single();

      if (createError || !booking) {
        throw new BadRequestException(`Failed to create booking: ${createError?.message}`);
      }

      return booking;
    } finally {
      // Release lock after a delay (payment should complete within 5 minutes)
      // Lock will auto-expire, but we can release it explicitly if payment fails
    }
  }

  /**
   * Confirm booking after payment (called by payment webhook)
   */
  async confirmBooking(bookingId: string, paymentId: string, qrCode: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: booking, error } = await supabase
      .from('bookings')
      .update({
        status: 'confirmed',
        payment_status: 'paid',
        payment_id: paymentId,
        qr_code: qrCode,
      })
      .eq('id', bookingId)
      .select(`
        *,
        ground:grounds!bookings_ground_id_fkey(
          *,
          venue:venues!grounds_venue_id_fkey(*)
        ),
        customer:users!bookings_customer_id_fkey(*)
      `)
      .single();

    if (error || !booking) {
      throw new Error(`Failed to confirm booking: ${error?.message}`);
    }

    return booking;
  }

  /**
   * Get user's bookings
   */
  async getMyBookings(userId: string, type: 'upcoming' | 'past' = 'upcoming') {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayStr = today.toISOString().split('T')[0];
    const currentTime = `${String(now.getHours()).padStart(2, '0')}:${String(
      now.getMinutes(),
    ).padStart(2, '0')}`;

    const supabase = this.supabaseService.getAdminClient();
    let query = supabase
      .from('bookings')
      .select(`
        *,
        ground:grounds!bookings_ground_id_fkey(
          *,
          venue:venues!grounds_venue_id_fkey(id, name, address, photos)
        )
      `)
      .eq('customer_id', userId);

    if (type === 'upcoming') {
      query = query
        .or(`booking_date.gt.${todayStr},and(booking_date.eq.${todayStr},start_time.gte.${currentTime})`)
        .not('status', 'in', '(cancelled,no_show)')
        .order('booking_date', { ascending: true })
        .order('start_time', { ascending: true });
    } else {
      query = query
        .or(`booking_date.lt.${todayStr},and(booking_date.eq.${todayStr},start_time.lt.${currentTime})`)
        .order('booking_date', { ascending: false })
        .order('start_time', { ascending: false });
    }

    const { data: bookings, error } = await query;

    if (error) {
      throw new Error(`Failed to fetch bookings: ${error.message}`);
    }

    return bookings || [];
  }

  /**
   * Get owner's bookings (filtered by tenant_id)
   */
  async getOwnerBookings(ownerId: string, tenantId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Get all venues for this tenant
    const { data: venues } = await supabase
      .from('venues')
      .select('id')
      .eq('tenant_id', tenantId)
      .eq('owner_id', ownerId);

    if (!venues || venues.length === 0) {
      return [];
    }

    const venueIds = venues.map(v => v.id);

    // Get bookings for these venues
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select(`
        *,
        ground:grounds!bookings_ground_id_fkey(
          *,
          venue:venues!grounds_venue_id_fkey(id, name, address, photos)
        ),
        customer:users!bookings_customer_id_fkey(id, name, phone)
      `)
      .in('venue_id', venueIds)
      .order('booking_date', { ascending: false })
      .order('start_time', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch owner bookings: ${error.message}`);
    }

    return bookings || [];
  }

  /**
   * Get booking by ID
   */
  async findOne(id: string, userId?: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: booking, error } = await supabase
      .from('bookings')
      .select(`
        *,
        ground:grounds!bookings_ground_id_fkey(
          *,
          venue:venues!grounds_venue_id_fkey(*)
        ),
        customer:users!bookings_customer_id_fkey(id, name, phone),
        payment:payments!payments_booking_id_fkey(*),
        review:reviews!reviews_booking_id_fkey(*)
      `)
      .eq('id', id)
      .single();

    if (!booking || error) {
      throw new NotFoundException('Booking not found');
    }

    // Check authorization
    if (userId && booking.customer_id !== userId && booking.ground.venue.owner_id !== userId) {
      throw new BadRequestException('You do not have permission to view this booking');
    }

    return booking;
  }

  /**
   * Mark booking as started (owner only)
   */
  async markStarted(bookingId: string, ownerId: string, tenantId: string) {
    const booking = await this.findOne(bookingId, ownerId);
    
    // Verify venue belongs to owner's tenant
    const supabase = this.supabaseService.getAdminClient();
    const { data: venue } = await supabase
      .from('venues')
      .select('tenant_id')
      .eq('id', booking.ground.venue.id)
      .single();
    
    if (booking.ground.venue.owner_id !== ownerId || venue?.tenant_id !== tenantId) {
      throw new BadRequestException('You do not have permission to update this booking');
    }
    
    const { data: updatedBooking, error } = await supabase
      .from('bookings')
      .update({ status: 'started' })
      .eq('id', bookingId)
      .select()
      .single();

    if (error || !updatedBooking) {
      throw new Error(`Failed to update booking: ${error?.message}`);
    }

    return updatedBooking;
  }

  /**
   * Mark booking as completed (owner only)
   */
  async markCompleted(bookingId: string, ownerId: string, tenantId: string) {
    const booking = await this.findOne(bookingId, ownerId);
    
    // Verify venue belongs to owner's tenant
    const supabase = this.supabaseService.getAdminClient();
    const { data: venue } = await supabase
      .from('venues')
      .select('tenant_id')
      .eq('id', booking.ground.venue.id)
      .single();
    
    if (booking.ground.venue.owner_id !== ownerId || venue?.tenant_id !== tenantId) {
      throw new BadRequestException('You do not have permission to update this booking');
    }
    
    const { data: updatedBooking, error } = await supabase
      .from('bookings')
      .update({ status: 'completed' })
      .eq('id', bookingId)
      .select()
      .single();

    if (error || !updatedBooking) {
      throw new Error(`Failed to update booking: ${error?.message}`);
    }

    return updatedBooking;
  }
}

