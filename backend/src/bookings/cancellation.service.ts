import { Injectable, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { PaymentsService } from '../payments/payments.service';

@Injectable()
export class CancellationService {
  constructor(
    private supabaseService: SupabaseService,
    @Inject(forwardRef(() => PaymentsService))
    private paymentsService: PaymentsService,
  ) {}

  /**
   * Cancel a booking and process refund if eligible
   * Policy: 80% refund if cancelled > 4 hours before, 0% otherwise
   */
  async cancelBooking(bookingId: string, userId: string): Promise<any> {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,
        payment:payments!payments_booking_id_fkey(*),
        customer:users!bookings_customer_id_fkey(*)
      `)
      .eq('id', bookingId)
      .single();

    if (!booking || bookingError) {
      throw new BadRequestException('Booking not found');
    }

    if (booking.customer_id !== userId) {
      throw new BadRequestException('You can only cancel your own bookings');
    }

    if (booking.status === 'cancelled') {
      throw new BadRequestException('Booking is already cancelled');
    }

    if (booking.status === 'completed') {
      throw new BadRequestException('Cannot cancel completed booking');
    }

    // Calculate time until booking
    const bookingDateTime = new Date(`${booking.booking_date}T${booking.start_time}`);
    const now = new Date();
    const hoursUntilBooking = (bookingDateTime.getTime() - now.getTime()) / (1000 * 60 * 60);

    // Check cancellation policy
    const isEligibleForRefund = hoursUntilBooking > 4;
    const refundPercentage = isEligibleForRefund ? 0.8 : 0;
    const refundAmount = isEligibleForRefund
      ? Number(booking.price) * refundPercentage
      : 0;

    // Update booking status
    const { error: updateError } = await supabase
      .from('bookings')
      .update({ status: 'cancelled' })
      .eq('id', bookingId);

    if (updateError) {
      throw new BadRequestException(`Failed to cancel booking: ${updateError.message}`);
    }

    // Process refund if eligible
    if (refundAmount > 0 && booking.payment) {
      await this.paymentsService.processRefund(booking.payment.id, refundAmount);
    }

    return {
      bookingId,
      cancelled: true,
      refundAmount,
      refundPercentage: refundPercentage * 100,
      message: isEligibleForRefund
        ? `Refund of Rs. ${refundAmount.toFixed(2)} will be processed within 3-5 business days`
        : 'No refund available as cancellation was less than 4 hours before booking',
    };
  }
}

