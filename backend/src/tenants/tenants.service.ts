import { Injectable, BadRequestException, NotFoundException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantDto } from './dto/update-tenant.dto';
import * as crypto from 'crypto';

@Injectable()
export class TenantsService {
  constructor(private supabaseService: SupabaseService) {}

  /**
   * Generate a secure random password
   */
  private generateTemporaryPassword(): string {
    const length = 12;
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
    const randomBytes = crypto.randomBytes(length);
    let password = '';
    for (let i = 0; i < length; i++) {
      password += charset[randomBytes[i] % charset.length];
    }
    return password;
  }

  /**
   * Create a new tenant and owner account (admin only)
   */
  async createTenant(dto: CreateTenantDto): Promise<{
    owner: any;
    tenant: any;
    temporaryPassword: string;
  }> {
    const { email, tenantName, temporaryPassword, name, phone } = dto;
    const supabase = this.supabaseService.getAdminClient();
    const adminAuth = supabase.auth.admin;

    // Check if tenant name already exists
    const { data: existingTenant } = await supabase
      .from('tenants')
      .select('id')
      .eq('name', tenantName)
      .single();

    if (existingTenant) {
      throw new ConflictException(`Tenant with name "${tenantName}" already exists`);
    }

    // Check if user with this email already exists in Supabase Auth
    const { data: existingAuthUsers } = await adminAuth.listUsers();
    const existingAuthUser = existingAuthUsers?.users.find((u: any) => u.email === email);

    if (existingAuthUser) {
      throw new ConflictException(`User with email "${email}" already exists`);
    }

    // Generate temporary password if not provided
    const tempPassword = temporaryPassword || this.generateTemporaryPassword();

    // Create user in Supabase Auth
    const { data: authData, error: authError } = await adminAuth.createUser({
      email,
      password: tempPassword,
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        name: name || null,
        phone: phone || null,
      },
    });

    if (authError) {
      throw new BadRequestException(`Failed to create user: ${authError.message}`);
    }

    if (!authData.user) {
      throw new BadRequestException('Failed to create user account');
    }

    const userId = authData.user.id;

      // Create user in our users table FIRST (before tenant, so tenant can reference it)
      // tenant_id will be null initially, we'll update it after tenant creation
      // Note: email is stored in Supabase Auth, not in public.users table
      const { error: userError } = await supabase
        .from('users')
        .insert({
          id: userId,
          phone: phone || email, // Use email as phone if not provided (phone is required, unique)
          name: name || null,
          role: 'owner',
          tenant_id: null, // Will be updated after tenant creation
          requires_password_change: true, // Force password change on first login
          temporary_password: tempPassword, // Store temporary password for admin view
        });

    if (userError) {
      // Rollback: delete auth user if user creation fails
      try {
        await adminAuth.deleteUser(userId);
      } catch (deleteError) {
        console.error('Failed to delete auth user after user creation failure:', deleteError);
      }
      throw new BadRequestException(`Failed to create user profile: ${userError.message}`);
    }

    // Create tenant (now that user exists in public.users)
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .insert({
        name: tenantName,
        owner_id: userId,
        status: 'active',
      })
      .select()
      .single();

    if (tenantError) {
      // Rollback: delete user and auth user if tenant creation fails
      try {
        await supabase.from('users').delete().eq('id', userId);
        await adminAuth.deleteUser(userId);
      } catch (deleteError) {
        console.error('Failed to delete user after tenant creation failure:', deleteError);
      }
      throw new BadRequestException(`Failed to create tenant: ${tenantError.message}`);
    }

    // Update user with tenant_id now that tenant exists
    // Keep temporary_password stored (don't clear it yet - admin needs to see it)
    const { error: updateUserError } = await supabase
      .from('users')
      .update({ tenant_id: tenant.id })
      .eq('id', userId);

    if (updateUserError) {
      // Rollback: delete tenant, user, and auth user
      try {
        await supabase.from('tenants').delete().eq('id', tenant.id);
        await supabase.from('users').delete().eq('id', userId);
        await adminAuth.deleteUser(userId);
      } catch (rollbackError) {
        console.error('Failed to rollback after user update failure:', rollbackError);
      }
      throw new BadRequestException(`Failed to update user with tenant_id: ${updateUserError.message}`);
    }

    // Get the created user from users table
    const { data: user } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    // Get email from Supabase Auth (email is not in users table)
    const { data: authUserData } = await adminAuth.getUserById(userId);
    const ownerEmail = authUserData?.user?.email || email; // Fallback to the email we used

    return {
      owner: {
        id: user.id,
        email: ownerEmail, // Get from auth, not from users table
        name: user.name,
        role: user.role,
        tenant_id: user.tenant_id,
        requires_password_change: user.requires_password_change,
      },
      tenant: {
        id: tenant.id,
        name: tenant.name,
        status: tenant.status,
        owner_id: tenant.owner_id,
      },
      temporaryPassword: tempPassword,
    };
  }

  /**
   * Reset owner password (admin only) - generates new temporary password
   */
  async resetOwnerPassword(ownerId: string): Promise<{ temporaryPassword: string }> {
    const supabase = this.supabaseService.getAdminClient();
    const adminAuth = supabase.auth.admin;

    // Check if user exists and is an owner
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, role')
      .eq('id', ownerId)
      .single();

    if (userError || !user) {
      throw new BadRequestException('Owner not found');
    }

    if (user.role !== 'owner') {
      throw new BadRequestException('User is not an owner');
    }

    // Generate new temporary password
    const tempPassword = this.generateTemporaryPassword();

    // Get user email from auth
    const { data: authUserData } = await adminAuth.getUserById(ownerId);
    const email = authUserData?.user?.email;

    if (!email) {
      throw new BadRequestException('Owner email not found');
    }

    // Update password in Supabase Auth
    const { error: updateError } = await adminAuth.updateUserById(ownerId, {
      password: tempPassword,
    });

    if (updateError) {
      throw new BadRequestException(`Failed to reset password: ${updateError.message}`);
    }

    // Update temporary_password and set requires_password_change flag
    const { error: dbUpdateError } = await supabase
      .from('users')
      .update({
        temporary_password: tempPassword,
        requires_password_change: true,
      })
      .eq('id', ownerId);

    if (dbUpdateError) {
      throw new BadRequestException(`Failed to update user: ${dbUpdateError.message}`);
    }

    return { temporaryPassword: tempPassword };
  }

  /**
   * Get all tenants (admin only)
   */
  async findAll(): Promise<any[]> {
    const supabase = this.supabaseService.getAdminClient();
    const adminAuth = supabase.auth.admin;
    
    // Get all tenants with owner info from users table
    const { data: tenants, error } = await supabase
      .from('tenants')
      .select(`
        *,
        owner:users!tenants_owner_id_fkey(id, name, phone, created_at, tenant_id, requires_password_change, temporary_password)
      `)
      .order('created_at', { ascending: false });

    if (error) {
      throw new BadRequestException(`Failed to fetch tenants: ${error.message}`);
    }

    // Get all auth users to get emails
    const { data: authUsersData } = await adminAuth.listUsers();
    const authUsers = authUsersData?.users || [];

    // Map tenants with owner email from auth
    const tenantsWithEmail = (tenants || []).map((tenant: any) => {
      const ownerId = tenant.owner?.id;
      const authUser = authUsers.find((u: any) => u.id === ownerId);
      
      return {
        ...tenant,
        owner: {
          ...tenant.owner,
          email: authUser?.email || null,
        },
      };
    });

    return tenantsWithEmail;
  }

  /**
   * Get tenant by ID
   */
  async findOne(tenantId: string): Promise<any> {
    const supabase = this.supabaseService.getAdminClient();
    const { data, error } = await supabase
      .from('tenants')
      .select(`
        *,
        owner:users!tenants_owner_id_fkey(id, email, name, phone, created_at)
      `)
      .eq('id', tenantId)
      .single();

    if (error || !data) {
      throw new NotFoundException('Tenant not found');
    }

    return data;
  }

  /**
   * Get tenant by owner ID
   */
  async findByOwnerId(ownerId: string): Promise<any> {
    const supabase = this.supabaseService.getAdminClient();
    const { data, error } = await supabase
      .from('tenants')
      .select('*')
      .eq('owner_id', ownerId)
      .single();

    if (error || !data) {
      throw new NotFoundException('Tenant not found for this owner');
    }

    return data;
  }

  /**
   * Get owner's tenant (for owner)
   */
  async getMyTenant(ownerId: string): Promise<any> {
    return this.findByOwnerId(ownerId);
  }

  /**
   * Update tenant (admin only)
   */
  async update(tenantId: string, dto: UpdateTenantDto): Promise<any> {
    const supabase = this.supabaseService.getAdminClient();
    
    const updateData: any = {};
    if (dto.name !== undefined) updateData.name = dto.name;
    if (dto.status !== undefined) updateData.status = dto.status;
    updateData.updated_at = new Date().toISOString();

    const { data, error } = await supabase
      .from('tenants')
      .update(updateData)
      .eq('id', tenantId)
      .select()
      .single();

    if (error || !data) {
      throw new BadRequestException(`Failed to update tenant: ${error?.message || 'Unknown error'}`);
    }

    return data;
  }

  /**
   * Delete tenant (admin only) - soft delete by setting status to suspended
   */
  async remove(tenantId: string): Promise<void> {
    const supabase = this.supabaseService.getAdminClient();
    
    // Soft delete: set status to suspended
    const { error } = await supabase
      .from('tenants')
      .update({ 
        status: 'suspended',
        updated_at: new Date().toISOString(),
      })
      .eq('id', tenantId);

    if (error) {
      throw new BadRequestException(`Failed to delete tenant: ${error.message}`);
    }
  }
}

