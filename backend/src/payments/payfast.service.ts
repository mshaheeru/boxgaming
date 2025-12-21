import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

@Injectable()
export class PayfastService {
  private merchantId: string;
  private merchantKey: string;
  private passphrase: string;
  private sandbox: boolean;
  private webhookSecret: string;

  constructor(private configService: ConfigService) {
    this.merchantId = this.configService.get<string>('PAYFAST_MERCHANT_ID', '');
    this.merchantKey = this.configService.get<string>('PAYFAST_MERCHANT_KEY', '');
    this.passphrase = this.configService.get<string>('PAYFAST_PASSPHRASE', '');
    this.sandbox = this.configService.get<string>('PAYFAST_SANDBOX', 'true') === 'true';
    this.webhookSecret = this.configService.get<string>('PAYFAST_WEBHOOK_SECRET', '');
  }

  /**
   * Initiate payment with PayFast
   */
  async initiatePayment(params: {
    amount: number;
    bookingId: string;
    paymentId: string;
    customerPhone: string;
    customerName: string;
    paymentMethod: string;
  }): Promise<string> {
    const baseUrl = this.sandbox
      ? 'https://sandbox.payfast.co.za'
      : 'https://www.payfast.co.za';

    // Build payment data
    const paymentData: any = {
      merchant_id: this.merchantId,
      merchant_key: this.merchantKey,
      return_url: `${process.env.APP_URL}/payment/success`,
      cancel_url: `${process.env.APP_URL}/payment/cancel`,
      notify_url: `${process.env.API_URL}/api/v1/webhooks/payment`,
      name_first: params.customerName.split(' ')[0] || 'Customer',
      name_last: params.customerName.split(' ').slice(1).join(' ') || '',
      email_address: `${params.customerPhone}@temp.com`, // PayFast requires email
      cell_number: params.customerPhone,
      amount: params.amount.toFixed(2),
      item_name: `Booking ${params.bookingId}`,
      custom_str1: params.bookingId,
      custom_str2: params.paymentId,
    };

    // Generate signature
    const signature = this.generateSignature(paymentData);
    paymentData.signature = signature;

    // Return payment URL
    const queryString = new URLSearchParams(paymentData).toString();
    return `${baseUrl}/eng/process?${queryString}`;
  }

  /**
   * Verify webhook signature
   */
  async verifyWebhook(payload: any, signature: string): Promise<boolean> {
    // PayFast webhook verification logic
    // This is a simplified version - implement according to PayFast docs
    const expectedSignature = crypto
      .createHmac('md5', this.webhookSecret)
      .update(JSON.stringify(payload))
      .digest('hex');

    return expectedSignature === signature;
  }

  /**
   * Process refund
   */
  async processRefund(transactionId: string, amount: number): Promise<any> {
    // PayFast refund API call
    // This is a placeholder - implement according to PayFast refund API
    return {
      success: true,
      refundId: `REF${Date.now()}`,
      amount,
    };
  }

  /**
   * Generate PayFast signature
   */
  private generateSignature(data: any): string {
    // Remove signature and empty values
    const cleanData: any = {};
    Object.keys(data)
      .sort()
      .forEach((key) => {
        if (data[key] !== '' && key !== 'signature') {
          cleanData[key] = data[key];
        }
      });

    // Create query string
    const queryString = new URLSearchParams(cleanData).toString();

    // Generate signature
    if (this.passphrase) {
      return crypto
        .createHash('md5')
        .update(queryString + `&passphrase=${this.passphrase}`)
        .digest('hex');
    } else {
      return crypto.createHash('md5').update(queryString).digest('hex');
    }
  }
}

