import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../common/redis.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(
    private supabaseService: SupabaseService,
    private redisService: RedisService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  async check() {
    try {
      // Check Supabase database connection
      const supabase = this.supabaseService.getAdminClient();
      const { error } = await supabase.from('users').select('count').limit(1);
      if (error && error.code !== 'PGRST116') {
        // PGRST116 is "no rows returned" which is fine for health check
        throw error;
      }

      // Check Redis connection (optional)
      let redisStatus = 'not_configured';
      try {
        const redisClient = this.redisService.getClient();
        if (redisClient) {
          await redisClient.ping();
          redisStatus = 'connected';
        } else {
          redisStatus = 'using_in_memory_fallback';
        }
      } catch (error) {
        // Redis might not be critical for health check
        redisStatus = 'disconnected';
        console.warn('Redis connection check failed:', error.message);
      }

      return {
        status: 'ok',
        timestamp: new Date().toISOString(),
        services: {
          database: 'connected',
          redis: redisStatus,
        },
      };
    } catch (error) {
      return {
        status: 'error',
        timestamp: new Date().toISOString(),
        error: error.message,
      };
    }
  }
}

