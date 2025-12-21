import { Injectable } from '@nestjs/common';
import * as QRCode from 'qrcode';

@Injectable()
export class QrService {
  /**
   * Generate unique booking code (e.g., "BK7X3M")
   */
  generateBookingCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing chars
    let code = 'BK';
    for (let i = 0; i < 4; i++) {
      code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
  }

  /**
   * Generate QR code image as base64
   */
  async generateQRCode(bookingId: string, bookingCode: string): Promise<string> {
    const data = JSON.stringify({
      bookingId,
      bookingCode,
      timestamp: Date.now(),
    });

    try {
      const qrCodeDataUrl = await QRCode.toDataURL(data, {
        errorCorrectionLevel: 'M',
        type: 'image/png',
        width: 300,
        margin: 1,
      });
      return qrCodeDataUrl;
    } catch (err) {
      throw new Error(`Failed to generate QR code: ${err.message}`);
    }
  }
}

