import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class PayoutsService {
  constructor(private supabaseService: SupabaseService) {}

  /**
   * Calculate and create weekly payouts for owners
   * Should be run as a cron job every Monday
   */
  async calculateWeeklyPayouts(commissionRate: number = 0.1) {
    const lastMonday = this.getLastMonday();
    const thisMonday = new Date();
    thisMonday.setDate(thisMonday.getDate() - thisMonday.getDay() + 1);
    thisMonday.setHours(0, 0, 0, 0);

    const supabase = this.supabaseService.getAdminClient();
    const lastMondayStr = lastMonday.toISOString().split('T')[0];
    const thisMondayStr = thisMonday.toISOString().split('T')[0];

    // Get all owners
    const { data: owners } = await supabase
      .from('users')
      .select(`
        id,
        venues:venues!venues_owner_id_fkey(
          id,
          bookings:bookings!bookings_venue_id_fkey(
            price,
            status,
            created_at
          )
        )
      `)
      .eq('role', 'owner');

    const payouts = [];

    for (const owner of owners || []) {
      let grossAmount = 0;

      // Calculate gross from all venues
      for (const venue of owner.venues || []) {
        for (const booking of venue.bookings || []) {
          const bookingDate = new Date(booking.created_at);
          if (
            bookingDate >= lastMonday &&
            bookingDate < thisMonday &&
            booking.status === 'completed'
          ) {
            grossAmount += Number(booking.price);
          }
        }
      }

      if (grossAmount > 0) {
        const commissionAmount = grossAmount * commissionRate;
        const netAmount = grossAmount - commissionAmount;

        const { data: payout } = await supabase
          .from('payouts')
          .insert({
            owner_id: owner.id,
            period_start: lastMondayStr,
            period_end: thisMondayStr,
            gross_amount: grossAmount,
            commission_amount: commissionAmount,
            net_amount: netAmount,
            status: 'pending',
          })
          .select()
          .single();

        if (payout) {
          payouts.push(payout);
        }
      }
    }

    return payouts;
  }

  /**
   * Get payouts for an owner
   */
  async getOwnerPayouts(ownerId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: payouts, error } = await supabase
      .from('payouts')
      .select('*')
      .eq('owner_id', ownerId)
      .order('period_end', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch payouts: ${error.message}`);
    }

    return payouts || [];
  }

  /**
   * Mark payout as paid
   */
  async markPaid(payoutId: string, bankReference: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: payout, error } = await supabase
      .from('payouts')
      .update({
        status: 'paid',
        paid_at: new Date().toISOString(),
        bank_reference: bankReference,
      })
      .eq('id', payoutId)
      .select()
      .single();

    if (error || !payout) {
      throw new Error(`Failed to update payout: ${error?.message}`);
    }

    return payout;
  }

  private getLastMonday(): Date {
    const today = new Date();
    const day = today.getDay();
    const diff = today.getDate() - day + (day === 0 ? -6 : 1); // Adjust when day is Sunday
    const lastMonday = new Date(today.setDate(diff));
    lastMonday.setHours(0, 0, 0, 0);
    lastMonday.setDate(lastMonday.getDate() - 7); // Go back one week
    return lastMonday;
  }
}

