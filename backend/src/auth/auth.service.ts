import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { SupabaseService } from '../supabase/supabase.service';
import { SignUpDto, SignInDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private supabaseService: SupabaseService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  /**
   * Sign up a new user
   */
  async signUp(dto: SignUpDto): Promise<{ accessToken: string; user: any }> {
    const { email, password, name } = dto;
    const adminAuth = this.supabaseService.getAdminClient().auth.admin;

    // Create user with admin client and auto-confirm email (for development)
    // This bypasses email confirmation requirement
    const { data: authData, error: signUpError } = await adminAuth.createUser({
      email,
      password,
      email_confirm: true, // Auto-confirm email so user can sign in immediately
      user_metadata: {
        name: name || null,
      },
    });

    if (signUpError) {
      throw new BadRequestException(signUpError.message || 'Failed to sign up');
    }

    if (!authData.user) {
      throw new BadRequestException('Failed to create user');
    }

    // Create or update user in our users table
    const supabase = this.supabaseService.getAdminClient();
    const userId = authData.user.id;

    // Check if user already exists in our users table
    const { data: existingUser } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (!existingUser) {
      // Create user in our users table
      const { error: createError } = await supabase
        .from('users')
        .insert({
          id: userId,
          phone: email, // Using email as phone for now (can be updated later)
          name: name || null,
          role: 'customer',
        });

      if (createError) {
        // If user creation fails, try to delete the auth user using admin client
        const adminAuth = this.supabaseService.getAdminClient().auth.admin;
        try {
          await adminAuth.deleteUser(userId);
        } catch (deleteError) {
          // Log but don't throw - the main error is the user creation failure
          console.error('Failed to delete auth user after profile creation failure:', deleteError);
        }
        throw new BadRequestException('Failed to create user profile');
      }
    }

    // Get the user from our table
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      throw new BadRequestException('Failed to retrieve user');
    }

    // Generate JWT token
    const payload = {
      sub: user.id,
      email: authData.user.email,
      role: user.role,
      tenant_id: user.tenant_id || null, // Include tenant_id for owners
    };

    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      user: {
        id: user.id,
        email: authData.user.email,
        name: user.name,
        role: user.role,
        tenant_id: user.tenant_id || null,
        requires_password_change: user.requires_password_change || false,
        createdAt: user.created_at || new Date().toISOString(),
      },
    };
  }

  /**
   * Sign in an existing user
   */
  async signIn(dto: SignInDto): Promise<{ accessToken: string; user: any }> {
    const { email, password } = dto;
    const auth = this.supabaseService.getAuth();
    const adminAuth = this.supabaseService.getAdminClient().auth.admin;

    // Try to sign in user with Supabase Auth
    let authData;
    let signInError;
    
    const signInResult = await auth.signInWithPassword({
      email,
      password,
    });
    
    authData = signInResult.data;
    signInError = signInResult.error;

    // If sign in fails due to unconfirmed email, auto-confirm and retry (for development)
    if (signInError && signInError.message?.includes('Email not confirmed')) {
      // Find the user by email and confirm their email
      const { data: usersData } = await adminAuth.listUsers();
      
      if (usersData?.users && Array.isArray(usersData.users)) {
        const user = usersData.users.find((u: any) => u.email === email);
        
        if (user?.id) {
          // Auto-confirm the email
          await adminAuth.updateUserById(user.id, {
            email_confirm: true,
          });
          
          // Retry sign in
          const retryResult = await auth.signInWithPassword({
            email,
            password,
          });
          authData = retryResult.data;
          signInError = retryResult.error;
        }
      }
    }

    if (signInError) {
      throw new UnauthorizedException(signInError.message || 'Invalid credentials');
    }

    if (!authData?.user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Get user from our users table
    const supabase = this.supabaseService.getAdminClient();
    const userId = authData.user.id;

    const { data: user, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      throw new UnauthorizedException('User not found');
    }

    // Log for debugging
    console.log(`[AuthService] Sign in - User ID: ${userId}, Requires password change: ${user.requires_password_change}`);

    // Generate JWT token
    const payload = {
      sub: user.id,
      email: authData.user.email,
      role: user.role,
      tenant_id: user.tenant_id || null, // Include tenant_id for owners
    };

    const accessToken = this.jwtService.sign(payload);

    return {
      accessToken,
      user: {
        id: user.id,
        email: authData.user.email,
        name: user.name,
        role: user.role,
        tenant_id: user.tenant_id || null,
        requires_password_change: user.requires_password_change || false,
        createdAt: user.created_at || new Date().toISOString(),
      },
    };
  }

  /**
   * Validate JWT token and return user
   */
  async validateUser(userId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: user, error } = await supabase
      .from('users')
      .select('id, phone, name, role, tenant_id, requires_password_change')
      .eq('id', userId)
      .single();

    if (!user || error) {
      throw new UnauthorizedException('User not found');
    }

    return user;
  }

  /**
   * Change password for owner (first login or regular change)
   */
  async changePassword(userId: string, currentPassword: string, newPassword: string): Promise<void> {
    const supabase = this.supabaseService.getAdminClient();
    const auth = this.supabaseService.getAuth();
    const adminAuth = this.supabaseService.getAdminClient().auth.admin;

    // Verify user exists in our users table
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, phone')
      .eq('id', userId)
      .single();

    if (userError || !user) {
      throw new UnauthorizedException('User not found');
    }

    // Get user email from Supabase Auth (not from users table)
    const { data: authUser, error: authUserError } = await adminAuth.getUserById(userId);
    
    if (authUserError || !authUser?.user?.email) {
      throw new UnauthorizedException('User not found in authentication system');
    }

    const userEmail = authUser.user.email;

    // Verify current password by attempting sign in
    const { error: signInError } = await auth.signInWithPassword({
      email: userEmail,
      password: currentPassword,
    });

    if (signInError) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    // Update password using admin client
    const { error: updateError } = await adminAuth.updateUserById(userId, {
      password: newPassword,
    });

    if (updateError) {
      throw new BadRequestException(`Failed to update password: ${updateError.message}`);
    }

    // Clear requires_password_change flag and temporary_password
    await supabase
      .from('users')
      .update({ 
        requires_password_change: false,
        temporary_password: null, // Clear temporary password after change
      })
      .eq('id', userId);
  }
}

