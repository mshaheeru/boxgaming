import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../common/redis.service';

export interface Slot {
  time: string;
  available: boolean;
  price: number;
}

@Injectable()
export class SlotService {
  constructor(
    private supabaseService: SupabaseService,
    private redisService: RedisService,
  ) {}

  /**
   * Get available slots for a ground on a specific date
   */
  async getAvailableSlots(
    groundId: string,
    date: Date,
    duration: 2 | 3,
  ): Promise<Slot[]> {
    // Check cache first
    const cacheKey = `slots:${groundId}:${date.toISOString().split('T')[0]}:${duration}`;
    const cached = await this.redisService.getCachedSlots(cacheKey);
    if (cached) {
      return cached;
    }

    // Get ground details
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: ground, error: groundError } = await supabase
      .from('grounds')
      .select(`
        *,
        venue:venues!grounds_venue_id_fkey(
          id,
          operating_hours:operating_hours!operating_hours_venue_id_fkey(*)
        ),
        operating_hours:operating_hours!operating_hours_ground_id_fkey(*)
      `)
      .eq('id', groundId)
      .single();

    if (!ground || groundError) {
      throw new Error('Ground not found');
    }

    // Get operating hours (prefer ground-specific, fallback to venue)
    const operatingHours = (ground.operating_hours && ground.operating_hours.length > 0)
      ? ground.operating_hours
      : (ground.venue?.operating_hours || []);

    if (operatingHours.length === 0) {
      return [];
    }

    // Get day of week (0 = Sunday, 6 = Saturday)
    const dayOfWeek = date.getDay();

    // Find operating hours for this day
    const dayHours = operatingHours.find((oh: any) => oh.day_of_week === dayOfWeek);
    if (!dayHours) {
      return [];
    }

    // Parse times
    const [openHour, openMin] = dayHours.open_time.split(':').map(Number);
    const [closeHour, closeMin] = dayHours.close_time.split(':').map(Number);

    const openTime = new Date(date);
    openTime.setHours(openHour, openMin, 0, 0);

    const closeTime = new Date(date);
    closeTime.setHours(closeHour, closeMin, 0, 0);

    // Generate slots
    const slots: Slot[] = [];
    const currentTime = new Date(openTime);

    while (currentTime.getTime() + duration * 60 * 60 * 1000 <= closeTime.getTime()) {
      const timeStr = `${String(currentTime.getHours()).padStart(2, '0')}:${String(
        currentTime.getMinutes(),
      ).padStart(2, '0')}`;

      slots.push({
        time: timeStr,
        available: true,
        price: duration === 2 ? Number(ground.price_2hr) : Number(ground.price_3hr),
      });

      // Move to next slot (start of next slot = end of current slot)
      currentTime.setHours(currentTime.getHours() + duration);
    }

    // Get existing bookings for this date
    const dateStr = date.toISOString().split('T')[0];
    const { data: bookings } = await supabase
      .from('bookings')
      .select('start_time, duration_hours')
      .eq('ground_id', groundId)
      .eq('booking_date', dateStr)
      .not('status', 'in', '(cancelled,no_show)');

    // Get blocked slots
    const { data: blockedSlots } = await supabase
      .from('blocked_slots')
      .select('start_time, end_time')
      .eq('ground_id', groundId)
      .eq('block_date', dateStr);

    // Mark unavailable slots
    slots.forEach((slot) => {
      // Check if slot conflicts with existing booking
      const hasBooking = (bookings || []).some((booking: any) => {
        const bookingStart = this.parseTime(booking.start_time);
        const bookingEnd = new Date(bookingStart);
        bookingEnd.setHours(bookingEnd.getHours() + booking.duration_hours);

        const slotStart = this.parseTime(slot.time);
        const slotEnd = new Date(slotStart);
        slotEnd.setHours(slotEnd.getHours() + duration);

        // Check for overlap
        return (
          (slotStart >= bookingStart && slotStart < bookingEnd) ||
          (slotEnd > bookingStart && slotEnd <= bookingEnd) ||
          (slotStart <= bookingStart && slotEnd >= bookingEnd)
        );
      });

      // Check if slot is blocked
      const isBlocked = (blockedSlots || []).some((blocked: any) => {
        const blockStart = this.parseTime(blocked.start_time);
        const blockEnd = this.parseTime(blocked.end_time);
        const slotStart = this.parseTime(slot.time);
        const slotEnd = new Date(slotStart);
        slotEnd.setHours(slotEnd.getHours() + duration);

        return (
          (slotStart >= blockStart && slotStart < blockEnd) ||
          (slotEnd > blockStart && slotEnd <= blockEnd) ||
          (slotStart <= blockStart && slotEnd >= blockEnd)
        );
      });

      slot.available = !hasBooking && !isBlocked;
    });

    // Cache result
    await this.redisService.cacheSlots(cacheKey, slots, 300);

    return slots;
  }

  /**
   * Parse time string (HH:MM) to Date object for today
   */
  private parseTime(timeStr: string): Date {
    const [hours, minutes] = timeStr.split(':').map(Number);
    const date = new Date();
    date.setHours(hours, minutes, 0, 0);
    return date;
  }
}

