import { Module, Global } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { RedisService } from './redis.service';
import { RolesGuard } from './guards/roles.guard';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CacheInterceptor } from './interceptors/cache.interceptor';

@Global()
@Module({
  imports: [PassportModule],
  providers: [RedisService, RolesGuard, JwtAuthGuard, CacheInterceptor],
  exports: [RedisService, RolesGuard, JwtAuthGuard, CacheInterceptor],
})
export class CommonModule {}

