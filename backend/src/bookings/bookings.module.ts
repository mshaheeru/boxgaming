import { Module, forwardRef } from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { SlotService } from './slot.service';
import { BookingLockService } from './booking-lock.service';
import { QrService } from './qr.service';
import { CancellationService } from './cancellation.service';
import { SupabaseModule } from '../supabase/supabase.module';
import { CommonModule } from '../common/common.module';
import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [
    SupabaseModule,
    CommonModule,
    forwardRef(() => PaymentsModule),
  ],
  controllers: [BookingsController],
  providers: [
    BookingsService,
    SlotService,
    BookingLockService,
    QrService,
    CancellationService,
  ],
  exports: [BookingsService, SlotService, QrService],
})
export class BookingsModule {}

