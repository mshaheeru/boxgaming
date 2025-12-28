import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { VenueQueryDto } from './dto/venue-query.dto';

@Injectable()
export class VenuesService {
  constructor(private supabaseService: SupabaseService) {}

  async create(ownerId: string, tenantId: string, dto: CreateVenueDto) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Verify owner has this tenant
    const { data: owner } = await supabase
      .from('users')
      .select('tenant_id')
      .eq('id', ownerId)
      .single();

    if (!owner || owner.tenant_id !== tenantId) {
      throw new ForbiddenException('Invalid tenant access');
    }
    
    const { data: venue, error } = await supabase
      .from('venues')
      .insert({
        ...dto,
        owner_id: ownerId,
        tenant_id: tenantId, // Auto-assign tenant_id
        status: 'pending', // Requires admin approval
        is_active: false, // New venues default to inactive
      })
      .select(`
        *,
        owner:users!owner_id(id, name, phone)
      `)
      .single();

    if (error || !venue) {
      throw new Error(`Failed to create venue: ${error?.message}`);
    }

    return {
      ...venue,
      ownerId: venue.owner_id,
      tenantId: venue.tenant_id,
      createdAt: venue.created_at,
      owner: venue.owner,
    };
  }

  /**
   * Find all venues
   * For owners: filtered by tenant_id
   * For customers: all active venues (all tenants)
   */
  async findAll(query: VenueQueryDto, tenantId?: string) {
    const { city, sportType, lat, lng, page = 1, limit = 10 } = query;
    const supabase = this.supabaseService.getAdminClient();
    const skip = (page - 1) * limit;

    let queryBuilder = supabase
      .from('venues')
      .select(`
        *,
        grounds!inner(id, name, sport_type, size, price_2hr, price_3hr),
        reviews(count)
      `);

    // Filter by tenant_id for owners, is_active for customers
    if (tenantId) {
      // Owner view: show all venues for their tenant (including inactive ones)
      queryBuilder = queryBuilder.eq('tenant_id', tenantId);
    } else {
      // Customer view: only active venues from all tenants
      queryBuilder = queryBuilder.eq('is_active', true);
    }

    queryBuilder = queryBuilder.eq('grounds.is_active', true);

    if (city) {
      queryBuilder = queryBuilder.eq('city', city);
    }

    if (sportType) {
      queryBuilder = queryBuilder.eq('grounds.sport_type', sportType);
    }

    // Get total count
    let countQuery = supabase
      .from('venues')
      .select('*', { count: 'exact', head: true });

    if (tenantId) {
      countQuery = countQuery.eq('tenant_id', tenantId);
    } else {
      countQuery = countQuery.eq('is_active', true);
    }

    if (city) {
      countQuery = countQuery.eq('city', city);
    }

    const [venuesResult, countResult] = await Promise.all([
      queryBuilder.order('rating', { ascending: false }).range(skip, skip + limit - 1),
      countQuery,
    ]);

    if (venuesResult.error) {
      throw new Error(`Failed to fetch venues: ${venuesResult.error.message}`);
    }

    // TODO: Calculate distance if lat/lng provided
    // For now, just return venues

    return {
      data: venuesResult.data || [],
      meta: {
        total: countResult.count || 0,
        page,
        limit,
        totalPages: Math.ceil((countResult.count || 0) / limit),
      },
    };
  }

  /**
   * Get owner's venues (filtered by tenant)
   */
  async findMyVenues(ownerId: string, tenantId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: venues, error } = await supabase
      .from('venues')
      .select(`
        *,
        grounds!grounds_venue_id_fkey(id, name, sport_type, size, price_2hr, price_3hr, is_active),
        operating_hours!operating_hours_venue_id_fkey(*)
      `)
      .eq('tenant_id', tenantId)
      .eq('owner_id', ownerId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch venues: ${error.message}`);
    }

    return venues || [];
  }

  async findOne(id: string, tenantId?: string, role?: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    let queryBuilder = supabase
      .from('venues')
      .select(`
        *,
        owner:users!owner_id(id, name, phone),
        grounds!grounds_venue_id_fkey(id, name, sport_type, size, price_2hr, price_3hr, is_active),
        operating_hours!operating_hours_venue_id_fkey(*),
        reviews!reviews_venue_id_fkey(
          id,
          rating,
          comment,
          created_at,
          customer:users!reviews_customer_id_fkey(id, name)
        )
      `)
      .eq('id', id);

    // For customers, only allow viewing active venues
    if (role === 'customer' || (!tenantId && role !== 'owner' && role !== 'admin')) {
      queryBuilder = queryBuilder.eq('is_active', true);
    }

    const { data: venue, error } = await queryBuilder.single();

    if (!venue || error) {
      throw new NotFoundException('Venue not found');
    }

    // Additional tenant check for owners
    if (tenantId && venue.tenant_id !== tenantId && role === 'owner') {
      throw new ForbiddenException('You do not have permission to view this venue');
    }

    // Get reviews count separately
    const { count } = await supabase
      .from('reviews')
      .select('*', { count: 'exact', head: true })
      .eq('venue_id', id);

    return {
      ...venue,
      ownerId: venue.owner_id,
      createdAt: venue.created_at,
      _count: {
        reviews: count || 0,
      },
    };
  }

  async update(id: string, ownerId: string, tenantId: string, dto: UpdateVenueDto) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Check if venue exists and belongs to owner's tenant
    const { data: venue, error: findError } = await supabase
      .from('venues')
      .select('owner_id, tenant_id')
      .eq('id', id)
      .single();

    if (!venue || findError) {
      throw new NotFoundException('Venue not found');
    }

    if (venue.owner_id !== ownerId || venue.tenant_id !== tenantId) {
      throw new ForbiddenException('You do not have permission to update this venue');
    }

    const { data: updatedVenue, error: updateError } = await supabase
      .from('venues')
      .update(dto)
      .eq('id', id)
      .select()
      .single();

    if (updateError || !updatedVenue) {
      throw new Error(`Failed to update venue: ${updateError?.message}`);
    }

    return updatedVenue;
  }

  async remove(id: string, ownerId: string, tenantId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Check if venue exists and belongs to owner's tenant
    const { data: venue, error: findError } = await supabase
      .from('venues')
      .select('owner_id, tenant_id')
      .eq('id', id)
      .single();

    if (!venue || findError) {
      throw new NotFoundException('Venue not found');
    }

    if (venue.owner_id !== ownerId || venue.tenant_id !== tenantId) {
      throw new ForbiddenException('You do not have permission to delete this venue');
    }

    const { error: deleteError } = await supabase
      .from('venues')
      .delete()
      .eq('id', id);

    if (deleteError) {
      throw new Error(`Failed to delete venue: ${deleteError.message}`);
    }

    return { message: 'Venue deleted successfully' };
  }

  async approve(id: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: venue, error } = await supabase
      .from('venues')
      .update({ status: 'active' })
      .eq('id', id)
      .select()
      .single();

    if (error || !venue) {
      throw new Error(`Failed to approve venue: ${error?.message}`);
    }

    return venue;
  }

  async suspend(id: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: venue, error } = await supabase
      .from('venues')
      .update({ status: 'suspended' })
      .eq('id', id)
      .select()
      .single();

    if (error || !venue) {
      throw new Error(`Failed to suspend venue: ${error?.message}`);
    }

    return venue;
  }

  /**
   * Activate a venue (owner only, tenant-scoped)
   */
  async activate(id: string, ownerId: string, tenantId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Check if venue exists and belongs to owner's tenant
    const { data: venue, error: findError } = await supabase
      .from('venues')
      .select('owner_id, tenant_id')
      .eq('id', id)
      .single();

    if (!venue || findError) {
      throw new NotFoundException('Venue not found');
    }

    if (venue.owner_id !== ownerId || venue.tenant_id !== tenantId) {
      throw new ForbiddenException('You do not have permission to activate this venue');
    }

    const { data: updatedVenue, error: updateError } = await supabase
      .from('venues')
      .update({ is_active: true })
      .eq('id', id)
      .select()
      .single();

    if (updateError || !updatedVenue) {
      throw new Error(`Failed to activate venue: ${updateError?.message}`);
    }

    return updatedVenue;
  }

  /**
   * Deactivate a venue (owner only, tenant-scoped)
   */
  async deactivate(id: string, ownerId: string, tenantId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Check if venue exists and belongs to owner's tenant
    const { data: venue, error: findError } = await supabase
      .from('venues')
      .select('owner_id, tenant_id')
      .eq('id', id)
      .single();

    if (!venue || findError) {
      throw new NotFoundException('Venue not found');
    }

    if (venue.owner_id !== ownerId || venue.tenant_id !== tenantId) {
      throw new ForbiddenException('You do not have permission to deactivate this venue');
    }

    const { data: updatedVenue, error: updateError } = await supabase
      .from('venues')
      .update({ is_active: false })
      .eq('id', id)
      .select()
      .single();

    if (updateError || !updatedVenue) {
      throw new Error(`Failed to deactivate venue: ${updateError?.message}`);
    }

    return updatedVenue;
  }
}

