import { Module } from '@nestjs/common';
import { GroundsService } from './grounds.service';
import { GroundsController } from './grounds.controller';
import { SupabaseModule } from '../supabase/supabase.module';
import { VenuesModule } from '../venues/venues.module';

@Module({
  imports: [SupabaseModule, VenuesModule],
  controllers: [GroundsController],
  providers: [GroundsService],
  exports: [GroundsService],
})
export class GroundsModule {}

