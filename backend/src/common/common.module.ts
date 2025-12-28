import { Module, Global } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { RedisService } from './redis.service';
import { RolesGuard } from './guards/roles.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Global()
@Module({
  imports: [PassportModule],
  providers: [RedisService, RolesGuard, JwtAuthGuard],
  exports: [RedisService, RolesGuard, JwtAuthGuard],
})
export class CommonModule {}

