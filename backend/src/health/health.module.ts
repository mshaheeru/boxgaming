import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { SupabaseModule } from '../supabase/supabase.module';
import { CommonModule } from '../common/common.module';

@Module({
  imports: [SupabaseModule, CommonModule],
  controllers: [HealthController],
})
export class HealthModule {}

