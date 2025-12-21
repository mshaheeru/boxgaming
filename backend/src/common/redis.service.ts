import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client: Redis | null = null;
  private isConnected = false;
  private hasLoggedError = false; // Track if we've already logged the error
  private inMemoryStore: Map<string, { value: string; expiresAt: number }> = new Map();

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const redisHost = this.configService.get('REDIS_HOST', 'localhost');
    const redisPort = this.configService.get('REDIS_PORT', 6379);
    const redisPassword = this.configService.get('REDIS_PASSWORD');

    // Only try to connect if Redis host is explicitly set and not empty
    if (redisHost && redisHost !== '' && redisHost !== 'localhost') {
      try {
        this.client = new Redis({
          host: redisHost,
          port: redisPort,
          password: redisPassword || undefined,
          family: 4, // Force IPv4 to avoid IPv6 issues
          retryStrategy: (times) => {
            // Stop retrying after 3 attempts
            if (times > 3) {
              if (!this.hasLoggedError) {
                console.log('Redis: Connection unavailable. Using in-memory fallback for caching.');
                this.hasLoggedError = true;
              }
              this.client = null; // Clear client to stop retries
              this.isConnected = false;
              return null; // Stop retrying
            }
            const delay = Math.min(times * 100, 1000);
            return delay;
          },
          enableOfflineQueue: false, // Don't queue commands when disconnected
          lazyConnect: true, // Don't connect immediately
          maxRetriesPerRequest: 0, // Don't retry individual requests
        });

        this.client.on('error', (err) => {
          if (!this.hasLoggedError) {
            console.log('Redis: Connection unavailable. Using in-memory fallback for caching.');
            this.hasLoggedError = true;
          }
          this.isConnected = false;
          // Clear client after first error to prevent further retries
          if (this.client) {
            this.client.disconnect();
            this.client = null;
          }
        });

        this.client.on('connect', () => {
          console.log('Redis: Connected successfully');
          this.isConnected = true;
          this.hasLoggedError = false; // Reset error flag on successful connection
        });

        this.client.on('close', () => {
          if (!this.hasLoggedError) {
            console.log('Redis: Connection closed. Using in-memory fallback.');
            this.hasLoggedError = true;
          }
          this.isConnected = false;
        });

        // Try to connect, but don't fail if it doesn't work
        this.client.connect().catch(() => {
          if (!this.hasLoggedError) {
            console.log('Redis: Connection unavailable. Using in-memory fallback for caching.');
            this.hasLoggedError = true;
          }
          this.isConnected = false;
          this.client = null;
        });
      } catch (error) {
        if (!this.hasLoggedError) {
          console.log('Redis: Not available. Using in-memory fallback for caching.');
          this.hasLoggedError = true;
        }
        this.isConnected = false;
        this.client = null;
      }
    } else {
      // Redis not configured - use in-memory silently
      this.client = null;
      this.isConnected = false;
    }

    // Clean up expired in-memory entries every minute
    setInterval(() => {
      this.cleanupInMemoryStore();
    }, 60000);
  }

  onModuleDestroy() {
    if (this.client) {
      this.client.disconnect();
    }
  }

  getClient(): Redis | null {
    return this.client;
  }

  private cleanupInMemoryStore() {
    const now = Date.now();
    for (const [key, data] of this.inMemoryStore.entries()) {
      if (data.expiresAt < now) {
        this.inMemoryStore.delete(key);
      }
    }
  }

  /**
   * Acquire a lock for a slot to prevent double booking
   * @param groundId Ground ID
   * @param date Booking date
   * @param time Start time
   * @param ttl Time to live in seconds (default: 300 = 5 minutes)
   * @returns Lock key if acquired, null if already locked
   */
  async acquireSlotLock(
    groundId: string,
    date: string,
    time: string,
    ttl: number = 300,
  ): Promise<string | null> {
    const lockKey = `slot:${groundId}:${date}:${time}`;
    
    if (this.client && this.isConnected) {
      try {
        const result = await this.client.set(lockKey, 'locked', 'EX', ttl, 'NX');
        return result === 'OK' ? lockKey : null;
      } catch (error) {
        // Fallback to in-memory
      }
    }
    
    // In-memory fallback
    if (this.inMemoryStore.has(lockKey)) {
      return null;
    }
    this.inMemoryStore.set(lockKey, {
      value: 'locked',
      expiresAt: Date.now() + ttl * 1000,
    });
    return lockKey;
  }

  /**
   * Release a slot lock
   * @param lockKey Lock key returned from acquireSlotLock
   */
  async releaseSlotLock(lockKey: string): Promise<void> {
    if (this.client && this.isConnected) {
      try {
        await this.client.del(lockKey);
        return;
      } catch (error) {
        // Fallback to in-memory
      }
    }
    this.inMemoryStore.delete(lockKey);
  }

  /**
   * Cache slot availability
   * @param key Cache key
   * @param data Slot data
   * @param ttl Time to live in seconds (default: 300 = 5 minutes)
   */
  async cacheSlots(key: string, data: any, ttl: number = 300): Promise<void> {
    if (this.client && this.isConnected) {
      try {
        await this.client.setex(key, ttl, JSON.stringify(data));
        return;
      } catch (error) {
        // Fallback to in-memory
      }
    }
    // In-memory fallback
    this.inMemoryStore.set(key, {
      value: JSON.stringify(data),
      expiresAt: Date.now() + ttl * 1000,
    });
  }

  /**
   * Get cached slot availability
   * @param key Cache key
   * @returns Cached data or null
   */
  async getCachedSlots(key: string): Promise<any | null> {
    if (this.client && this.isConnected) {
      try {
        const data = await this.client.get(key);
        return data ? JSON.parse(data) : null;
      } catch (error) {
        // Fallback to in-memory
      }
    }
    // In-memory fallback
    const stored = this.inMemoryStore.get(key);
    if (stored && stored.expiresAt > Date.now()) {
      return JSON.parse(stored.value);
    }
    if (stored) {
      this.inMemoryStore.delete(key);
    }
    return null;
  }

  /**
   * Set OTP with expiration
   * @param phone Phone number
   * @param otp OTP code
   * @param ttl Time to live in seconds (default: 300 = 5 minutes)
   */
  async setOTP(phone: string, otp: string, ttl: number = 300): Promise<void> {
    const key = `otp:${phone}`;
    
    if (this.client && this.isConnected) {
      try {
        await this.client.setex(key, ttl, otp);
        return;
      } catch (error) {
        // Fallback to in-memory
      }
    }
    // In-memory fallback
    this.inMemoryStore.set(key, {
      value: otp,
      expiresAt: Date.now() + ttl * 1000,
    });
  }

  /**
   * Verify and delete OTP
   * @param phone Phone number
   * @param otp OTP code
   * @returns true if valid, false otherwise
   */
  async verifyOTP(phone: string, otp: string): Promise<boolean> {
    const key = `otp:${phone}`;
    
    if (this.client && this.isConnected) {
      try {
        const storedOTP = await this.client.get(key);
        if (storedOTP === otp) {
          await this.client.del(key);
          return true;
        }
        return false;
      } catch (error) {
        // Fallback to in-memory
      }
    }
    
    // In-memory fallback
    const stored = this.inMemoryStore.get(key);
    if (stored && stored.expiresAt > Date.now()) {
      if (stored.value === otp) {
        this.inMemoryStore.delete(key);
        return true;
      }
      return false;
    }
    if (stored) {
      this.inMemoryStore.delete(key);
    }
    return false;
  }
}

