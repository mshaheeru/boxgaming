import { Injectable, NotFoundException, Inject, forwardRef } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { PayfastService } from './payfast.service';
import { BookingsService } from '../bookings/bookings.service';
import { QrService } from '../bookings/qr.service';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';

@Injectable()
export class PaymentsService {
  constructor(
    private supabaseService: SupabaseService,
    private payfastService: PayfastService,
    @Inject(forwardRef(() => BookingsService))
    private bookingsService: BookingsService,
    private qrService: QrService,
  ) {}

  /**
   * Initiate payment for a booking
   */
  async initiatePayment(bookingId: string, dto: InitiatePaymentDto) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select(`
        *,
        ground:grounds!bookings_ground_id_fkey(
          *,
          venue:venues!grounds_venue_id_fkey(*)
        ),
        customer:users!bookings_customer_id_fkey(*)
      `)
      .eq('id', bookingId)
      .single();

    if (!booking || bookingError) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.payment_status === 'paid') {
      throw new Error('Booking is already paid');
    }

    // Create payment record
    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .insert({
        booking_id: bookingId,
        amount: booking.price,
        gateway: dto.paymentMethod,
        status: 'pending',
      })
      .select()
      .single();

    if (paymentError || !payment) {
      throw new Error(`Failed to create payment: ${paymentError?.message}`);
    }

    // Initiate payment with gateway
    const paymentUrl = await this.payfastService.initiatePayment({
      amount: Number(booking.price),
      bookingId,
      paymentId: payment.id,
      customerPhone: booking.customer.phone,
      customerName: booking.customer.name || 'Customer',
      paymentMethod: dto.paymentMethod,
    });

    return {
      paymentId: payment.id,
      paymentUrl,
      amount: Number(booking.price),
    };
  }

  /**
   * Handle payment webhook from gateway
   */
  async handleWebhook(payload: any, signature: string) {
    // Verify webhook signature
    const isValid = await this.payfastService.verifyWebhook(payload, signature);
    if (!isValid) {
      throw new Error('Invalid webhook signature');
    }

    const { paymentId, status, transactionId } = payload;
    const supabase = this.supabaseService.getAdminClient();

    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .select(`
        *,
        booking:bookings!payments_booking_id_fkey(*)
      `)
      .eq('id', paymentId)
      .single();

    if (!payment || paymentError) {
      throw new NotFoundException('Payment not found');
    }

    if (status === 'success') {
      // Generate QR code
      const qrCode = await this.qrService.generateQRCode(
        payment.booking.id,
        payment.booking.booking_code,
      );

      // Update payment
      await supabase
        .from('payments')
        .update({
          status: 'success',
          gateway_transaction_id: transactionId,
        })
        .eq('id', paymentId);

      // Confirm booking
      await this.bookingsService.confirmBooking(
        payment.booking.id,
        transactionId,
        qrCode,
      );

      // TODO: Send push notifications
    } else if (status === 'failed') {
      await supabase
        .from('payments')
        .update({ status: 'failed' })
        .eq('id', paymentId);

      // TODO: Release booking lock, notify user
    }

    return { success: true };
  }

  /**
   * Process refund for a payment
   */
  async processRefund(paymentId: string, amount: number) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: payment, error: paymentError } = await supabase
      .from('payments')
      .select('gateway_transaction_id')
      .eq('id', paymentId)
      .single();

    if (!payment || paymentError) {
      throw new NotFoundException('Payment not found');
    }

    // Call gateway refund API
    const refundResult = await this.payfastService.processRefund(
      payment.gateway_transaction_id,
      amount,
    );

    // Update payment status
    await supabase
      .from('payments')
      .update({ status: 'refunded' })
      .eq('id', paymentId);

    return refundResult;
  }
}

