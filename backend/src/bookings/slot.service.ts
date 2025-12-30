import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../common/redis.service';

export interface Slot {
  time: string;
  available: boolean;
  price: number;
}

/**
 * Represents a free time segment (operating hours minus bookings/blocks)
 */
interface FreeSegment {
  start: Date;
  end: Date;
}

@Injectable()
export class SlotService {
  // Time granularity for slot generation (30 minutes)
  private readonly TIME_GRANULARITY_MINUTES = 30;
  
  // Allowed booking durations in minutes (2hr = 120, 3hr = 180)
  private readonly ALLOWED_DURATIONS_MINUTES = [120, 180];
  
  // Maximum time to check feasibility for (24 hours in minutes)
  private readonly MAX_TIME_MINUTES = 24 * 60;
  
  // Precomputed DP array for feasibility (cached per instance)
  private feasibleCache: boolean[] | null = null;

  constructor(
    private supabaseService: SupabaseService,
    private redisService: RedisService,
  ) {}

  /**
   * Get available slots for a ground on a specific date
   * 
   * This implementation prevents "wasted time" by only showing start times
   * where the remaining free time on both sides can be filled with 2hr/3hr packages.
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
    
    // First, get the ground
    const { data: ground, error: groundError } = await supabase
      .from('grounds')
      .select('*')
      .eq('id', groundId)
      .single();

    if (!ground || groundError) {
      throw new Error(`Ground not found: ${groundError?.message || 'Unknown error'}`);
    }

    // Get operating hours for this ground
    const { data: groundOperatingHours, error: ohError } = await supabase
      .from('operating_hours')
      .select('*')
      .eq('ground_id', groundId);

    if (ohError) {
      throw new Error(`Failed to fetch operating hours: ${ohError.message}`);
    }

    // Get operating hours (prefer ground-specific, fallback to venue)
    let operatingHours = groundOperatingHours || [];
    
    // If no ground-level operating hours, try venue-level (legacy support)
    if (operatingHours.length === 0 && ground.venue_id) {
      const { data: venueOperatingHours, error: venueOhError } = await supabase
        .from('operating_hours')
        .select('*')
        .eq('venue_id', ground.venue_id)
        .is('ground_id', null);
      
      if (venueOhError) {
        throw new Error(`Failed to fetch venue operating hours: ${venueOhError.message}`);
      }
      
      operatingHours = venueOperatingHours || [];
    }

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

    // Parse operating times
    const [openHour, openMin] = dayHours.open_time.split(':').map(Number);
    const [closeHour, closeMin] = dayHours.close_time.split(':').map(Number);

    const openTime = new Date(date);
    openTime.setHours(openHour, openMin, 0, 0);

    const closeTime = new Date(date);
    closeTime.setHours(closeHour, closeMin, 0, 0);
    
    // Handle overnight hours (e.g., 17:00 - 02:30)
    // If closeTime is earlier than openTime, it means it's the next day
    if (closeTime.getTime() < openTime.getTime()) {
      closeTime.setDate(closeTime.getDate() + 1);
    }

    // Get existing bookings and blocked slots
    const dateStr = date.toISOString().split('T')[0];
    const { data: bookings } = await supabase
      .from('bookings')
      .select('start_time, duration_hours')
      .eq('ground_id', groundId)
      .eq('booking_date', dateStr)
      .not('status', 'in', '(cancelled,no_show)');

    const { data: blockedSlots } = await supabase
      .from('blocked_slots')
      .select('start_time, end_time')
      .eq('ground_id', groundId)
      .eq('block_date', dateStr);

    // Find free segments (operating hours minus bookings/blocks)
    const freeSegments = this.findFreeSegments(
      openTime,
      closeTime,
      bookings || [],
      blockedSlots || [],
    );

    // Precompute feasibility array (cached for performance)
    const feasible = this.getFeasibleDurations();

    // Generate valid slots from free segments
    const slots: Slot[] = [];
    const durationMinutes = duration * 60;
    const price = duration === 2 ? Number(ground.price_2hr) : Number(ground.price_3hr);

    for (const segment of freeSegments) {
      const segmentSlots = this.generateValidSlotsFromSegment(
        segment,
        durationMinutes,
        feasible,
        price,
      );
      slots.push(...segmentSlots);
    }

    // Sort slots by time
    slots.sort((a, b) => a.time.localeCompare(b.time));

    // Cache result
    await this.redisService.cacheSlots(cacheKey, slots, 300);

    return slots;
  }

  /**
   * Find free time segments by subtracting bookings and blocks from operating hours
   */
  private findFreeSegments(
    openTime: Date,
    closeTime: Date,
    bookings: any[],
    blockedSlots: any[],
  ): FreeSegment[] {
    // Combine bookings and blocks into occupied intervals
    const occupied: Array<{ start: Date; end: Date }> = [];

    // Add bookings
    for (const booking of bookings) {
      const start = this.parseTimeForDate(booking.start_time, openTime);
      const end = new Date(start);
      end.setMinutes(end.getMinutes() + booking.duration_hours * 60);
      occupied.push({ start, end });
    }

    // Add blocked slots
    for (const blocked of blockedSlots) {
      const start = this.parseTimeForDate(blocked.start_time, openTime);
      const end = this.parseTimeForDate(blocked.end_time, openTime);
      occupied.push({ start, end });
    }

    // Sort occupied intervals by start time
    occupied.sort((a, b) => a.start.getTime() - b.start.getTime());

    // Find free segments
    const freeSegments: FreeSegment[] = [];
    let currentStart = new Date(openTime);

    for (const interval of occupied) {
      // If there's a gap before this occupied interval, it's a free segment
      if (currentStart.getTime() < interval.start.getTime()) {
        freeSegments.push({
          start: new Date(currentStart),
          end: new Date(interval.start),
        });
      }
      // Move current start to the end of this occupied interval
      currentStart = new Date(Math.max(currentStart.getTime(), interval.end.getTime()));
    }

    // Add remaining free segment after last occupied interval
    if (currentStart.getTime() < closeTime.getTime()) {
      freeSegments.push({
        start: new Date(currentStart),
        end: new Date(closeTime),
      });
    }

    return freeSegments;
  }

  /**
   * Generate valid slots from a free segment
   * Only includes start times where both left and right gaps are feasible
   */
  private generateValidSlotsFromSegment(
    segment: FreeSegment,
    durationMinutes: number,
    feasible: boolean[],
    price: number,
  ): Slot[] {
    const slots: Slot[] = [];
    const segmentStartMinutes = this.getMinutesFromMidnight(segment.start);
    let segmentEndMinutes = this.getMinutesFromMidnight(segment.end);
    
    // Handle overnight hours: if end time is earlier than start time, it's the next day
    const isOvernight = segmentEndMinutes < segmentStartMinutes;
    const totalSegmentMinutes = isOvernight 
      ? (24 * 60 - segmentStartMinutes) + segmentEndMinutes
      : segmentEndMinutes - segmentStartMinutes;
    
    const granularityMinutes = this.TIME_GRANULARITY_MINUTES;

    // Generate candidate start times with granularity
    // For overnight segments, generate times from start to midnight, then from 00:00 to end
    let currentStartMinutes = segmentStartMinutes;
    const maxStartMinutes = isOvernight ? 24 * 60 : segmentEndMinutes;
    
    // First, generate slots that start before midnight (for overnight) or before end (for same day)
    while (currentStartMinutes < maxStartMinutes) {
      // Check if slot fits
      let slotEndMinutes: number;
      if (isOvernight && currentStartMinutes + durationMinutes > 24 * 60) {
        // Slot crosses midnight
        const minutesBeforeMidnight = 24 * 60 - currentStartMinutes;
        const minutesAfterMidnight = durationMinutes - minutesBeforeMidnight;
        if (minutesAfterMidnight > segmentEndMinutes) {
          // Slot doesn't fit
          break;
        }
        slotEndMinutes = minutesAfterMidnight;
      } else {
        // Slot fits entirely before midnight (overnight) or before end (same day)
        slotEndMinutes = currentStartMinutes + durationMinutes;
        if (!isOvernight && slotEndMinutes > segmentEndMinutes) {
          break; // Can't fit anymore
        }
      }
      
      // Calculate left and right gaps
      const leftMinutes = currentStartMinutes - segmentStartMinutes;
      let rightMinutes: number;
      if (isOvernight) {
        if (currentStartMinutes + durationMinutes <= 24 * 60) {
          // Slot ends before midnight
          rightMinutes = totalSegmentMinutes - (leftMinutes + durationMinutes);
        } else {
          // Slot crosses midnight
          const minutesBeforeMidnight = 24 * 60 - currentStartMinutes;
          const minutesAfterMidnight = durationMinutes - minutesBeforeMidnight;
          rightMinutes = segmentEndMinutes - minutesAfterMidnight;
        }
      } else {
        rightMinutes = segmentEndMinutes - (currentStartMinutes + durationMinutes);
      }

      // Check if both gaps are feasible (can be formed by 2hr/3hr combinations) or are 0
      // For overnight hours, be more lenient with right gap since overnight segments are inherently different
      const leftFeasible = leftMinutes === 0 || (leftMinutes < feasible.length && feasible[leftMinutes]);
      let rightFeasible: boolean;
      
      if (isOvernight) {
        // For overnight hours, only require left gap to be feasible
        // Right gap can be any value (we're more lenient for overnight)
        rightFeasible = true;
      } else {
        // For same-day hours, require both gaps to be feasible
        rightFeasible = rightMinutes === 0 || 
          (rightMinutes < feasible.length && feasible[rightMinutes]) ||
          (rightMinutes <= 180); // Allow up to 180 minutes (max booking duration) of "wasted" time
      }

      if (leftFeasible && rightFeasible) {
        // This is a valid start time
        const timeStr = this.minutesToTimeString(currentStartMinutes);
        slots.push({
          time: timeStr,
          available: true,
          price,
        });
      }
      
      // Move to next candidate time
      currentStartMinutes += granularityMinutes;
    }

    return slots;
  }

  /**
   * Precompute which time durations (in minutes) can be formed by 2hr/3hr combinations
   * Uses dynamic programming: feasible[t] = feasible[t-120] OR feasible[t-180]
   */
  private getFeasibleDurations(): boolean[] {
    // Return cached result if available
    if (this.feasibleCache) {
      return this.feasibleCache;
    }

    const feasible = new Array<boolean>(this.MAX_TIME_MINUTES + 1).fill(false);
    feasible[0] = true; // 0 minutes is always feasible (empty)

    // Fill DP array
    for (let t = 1; t <= this.MAX_TIME_MINUTES; t++) {
      for (const duration of this.ALLOWED_DURATIONS_MINUTES) {
        if (t >= duration && feasible[t - duration]) {
          feasible[t] = true;
          break; // Found a way, no need to check other durations
        }
      }
    }

    // Cache for future use
    this.feasibleCache = feasible;
    return feasible;
  }

  /**
   * Convert minutes from midnight to time string (HH:MM)
   */
  private minutesToTimeString(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}`;
  }

  /**
   * Get minutes from midnight for a given date
   */
  private getMinutesFromMidnight(date: Date): number {
    return date.getHours() * 60 + date.getMinutes();
  }

  /**
   * Parse time string (HH:MM) to Date object using a reference date
   */
  private parseTimeForDate(timeStr: string, referenceDate: Date): Date {
    const [hours, minutes] = timeStr.split(':').map(Number);
    const date = new Date(referenceDate);
    date.setHours(hours, minutes, 0, 0);
    return date;
  }

  /**
   * Parse time string (HH:MM) to Date object for today (legacy method, kept for compatibility)
   */
  private parseTime(timeStr: string): Date {
    const [hours, minutes] = timeStr.split(':').map(Number);
    const date = new Date();
    date.setHours(hours, minutes, 0, 0);
    return date;
  }
}

