import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private supabaseClient: SupabaseClient;
  private supabaseAdminClient: SupabaseClient;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseAnonKey = this.configService.get<string>('SUPABASE_ANON_KEY');
    const supabaseServiceRoleKey = this.configService.get<string>(
      'SUPABASE_SERVICE_ROLE_KEY',
    );

    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error(
        'Missing Supabase configuration. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
      );
    }

    // Client for regular operations (uses anon key)
    this.supabaseClient = createClient(supabaseUrl, supabaseAnonKey);

    // Admin client for server-side operations (uses service role key)
    if (supabaseServiceRoleKey) {
      this.supabaseAdminClient = createClient(
        supabaseUrl,
        supabaseServiceRoleKey,
        {
          auth: {
            autoRefreshToken: false,
            persistSession: false,
          },
        },
      );
    } else {
      // Fallback to anon key if service role key not provided
      this.supabaseAdminClient = this.supabaseClient;
    }
  }

  /**
   * Get Supabase client for regular operations
   * Use this for client-side operations that respect Row Level Security (RLS)
   */
  getClient(): SupabaseClient {
    return this.supabaseClient;
  }

  /**
   * Get Supabase admin client for server-side operations
   * Use this for operations that bypass Row Level Security (RLS)
   */
  getAdminClient(): SupabaseClient {
    return this.supabaseAdminClient;
  }

  /**
   * Get Supabase auth client
   */
  getAuth() {
    return this.supabaseAdminClient.auth;
  }

  /**
   * Get Supabase storage client
   */
  getStorage() {
    return this.supabaseAdminClient.storage;
  }
}

