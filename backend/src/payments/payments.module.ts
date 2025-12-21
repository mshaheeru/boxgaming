import { Module, forwardRef } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { PayfastService } from './payfast.service';
import { SupabaseModule } from '../supabase/supabase.module';
import { BookingsModule } from '../bookings/bookings.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    SupabaseModule,
    forwardRef(() => BookingsModule),
    NotificationsModule,
  ],
  controllers: [PaymentsController],
  providers: [PaymentsService, PayfastService],
  exports: [PaymentsService],
})
export class PaymentsModule {}

