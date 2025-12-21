import { Injectable, ConflictException } from '@nestjs/common';
import { RedisService } from '../common/redis.service';

@Injectable()
export class BookingLockService {
  constructor(private redisService: RedisService) {}

  /**
   * Acquire lock for a slot to prevent double booking
   * @returns Lock key if acquired, throws if already locked
   */
  async acquireLock(
    groundId: string,
    date: string,
    time: string,
  ): Promise<string> {
    const lockKey = await this.redisService.acquireSlotLock(groundId, date, time);
    if (!lockKey) {
      throw new ConflictException('This slot is currently being booked by another user');
    }
    return lockKey;
  }

  /**
   * Release lock for a slot
   */
  async releaseLock(lockKey: string): Promise<void> {
    await this.redisService.releaseSlotLock(lockKey);
  }
}

