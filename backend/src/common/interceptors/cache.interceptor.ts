import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import { RedisService } from '../redis.service';

@Injectable()
export class CacheInterceptor implements NestInterceptor {
  constructor(private redisService: RedisService) {}

  async intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Promise<Observable<any>> {
    const request = context.switchToHttp().getRequest();
    const { method, url, query, params } = request;

    // Only cache GET requests
    if (method !== 'GET') {
      return next.handle();
    }

    // Build cache key from URL and query params
    const cacheKey = this.buildCacheKey(url, query, params);
    
    // Try to get from cache
    try {
      const cached = await this.redisService.get(cacheKey);
      if (cached) {
        return of(JSON.parse(cached));
      }
    } catch (error) {
      // If cache read fails, continue to handler
      console.warn('Cache read failed:', error);
    }

    // If not in cache, execute handler and cache result
    return next.handle().pipe(
      tap(async (data) => {
        try {
          // Cache for 5 minutes (300 seconds)
          await this.redisService.set(cacheKey, JSON.stringify(data), 300);
        } catch (error) {
          // Silently fail if cache write fails
          console.warn('Cache write failed:', error);
        }
      }),
    );
  }

  private buildCacheKey(url: string, query: any, params: any): string {
    const queryStr = Object.keys(query || {})
      .sort()
      .map((key) => `${key}=${query[key]}`)
      .join('&');
    const paramsStr = Object.keys(params || {})
      .sort()
      .map((key) => `${key}=${params[key]}`)
      .join('&');
    
    return `cache:${url}${queryStr ? `?${queryStr}` : ''}${paramsStr ? `&${paramsStr}` : ''}`;
  }
}

