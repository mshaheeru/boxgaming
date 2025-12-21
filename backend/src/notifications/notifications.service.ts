import { Injectable } from '@nestjs/common';
import { FcmService } from './fcm.service';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class NotificationsService {
  constructor(
    private fcmService: FcmService,
    private supabaseService: SupabaseService,
  ) {}

  /**
   * Send booking confirmation notification
   */
  async sendBookingConfirmation(bookingId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: booking } = await supabase
      .from('bookings')
      .select(`
        *,
        customer:users!bookings_customer_id_fkey(*),
        ground:grounds!bookings_ground_id_fkey(
          *,
          venue:venues!grounds_venue_id_fkey(*)
        )
      `)
      .eq('id', bookingId)
      .single();

    if (!booking) {
      return;
    }

    // Send to customer
    await this.fcmService.sendNotification(
      booking.customer.id,
      'Booking Confirmed',
      `Your booking at ${booking.ground.venue.name} is confirmed. Booking code: ${booking.booking_code}`,
      {
        type: 'booking_confirmed',
        bookingId,
      },
    );

    // Send to owner
    const { data: owner } = await supabase
      .from('users')
      .select('id')
      .eq('id', booking.ground.venue.owner_id)
      .single();

    if (owner) {
      await this.fcmService.sendNotification(
        owner.id,
        'New Booking',
        `${booking.customer.name || 'Customer'} booked ${booking.ground.name} on ${booking.booking_date}`,
        {
          type: 'new_booking',
          bookingId,
        },
      );
    }
  }

  /**
   * Send booking reminder (2 hours before)
   */
  async sendBookingReminder(bookingId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: booking } = await supabase
      .from('bookings')
      .select(`
        *,
        customer:users!bookings_customer_id_fkey(*),
        ground:grounds!bookings_ground_id_fkey(
          *,
          venue:venues!grounds_venue_id_fkey(*)
        )
      `)
      .eq('id', bookingId)
      .single();

    if (!booking) {
      return;
    }

    await this.fcmService.sendNotification(
      booking.customer.id,
      'Booking Reminder',
      `Your booking at ${booking.ground.venue.name} starts in 2 hours`,
      {
        type: 'booking_reminder',
        bookingId,
      },
    );
  }
}

