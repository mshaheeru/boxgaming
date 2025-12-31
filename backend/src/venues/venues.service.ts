import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../common/redis.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { VenueQueryDto } from './dto/venue-query.dto';
import { CreateOperatingHoursDto } from './dto/create-operating-hours.dto';

@Injectable()
export class VenuesService {
  constructor(
    private supabaseService: SupabaseService,
    private redisService: RedisService,
  ) {}

  /**
   * Invalidate venue-related cache
   */
  private async invalidateVenueCache(venueId?: string) {
    try {
      // Invalidate all venue list caches
      await this.redisService.delByPattern('cache:/api/v1/venues*');
      // Invalidate specific venue detail cache if ID provided
      if (venueId) {
        await this.redisService.del(`cache:/api/v1/venues/${venueId}`);
      }
    } catch (error) {
      // Silently fail - cache invalidation is not critical
      console.warn('Cache invalidation failed:', error);
    }
  }

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

    // Invalidate cache after creating venue
    await this.invalidateVenueCache();

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
        grounds(id, name, sport_type, size, price_2hr, price_3hr, is_active),
        reviews(count)
      `);

    // Filter by tenant_id for owners, is_active for customers
    if (tenantId) {
      // Owner view: show all venues for their tenant (including inactive ones)
      queryBuilder = queryBuilder.eq('tenant_id', tenantId);
    } else {
      // Customer view: only active venues from all tenants
      // Note: We filter for valid owner_id and tenant_id in application layer below
      queryBuilder = queryBuilder.eq('is_active', true);
    }

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
      // Customer view: only count active venues
      // Note: We filter for valid owner_id and tenant_id in application layer
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

    // Filter venues: For customers, ensure they have valid owner_id and tenant_id (not seeded data)
    // Note: Venues without grounds can still be shown (grounds can be added later)
    let filteredVenues = venuesResult.data || [];
    if (!tenantId) {
      // Customer view: filter to ensure valid owner/tenant (not seeded data)
      filteredVenues = filteredVenues.filter((venue: any) => {
        // Must have valid owner_id and tenant_id
        if (!venue.owner_id || !venue.tenant_id) {
          return false;
        }
        // Venues can be shown even without grounds (they'll be bookable once grounds are added)
        return true;
      });
    }

    // Deduplicate venues: Supabase join with grounds can create duplicate venue rows
    // Group by venue ID and merge grounds arrays
    const venueMap = new Map<string, any>();
    for (const venue of filteredVenues) {
      const venueId = venue.id;
      if (venueMap.has(venueId)) {
        // Merge grounds if venue already exists
        const existingVenue = venueMap.get(venueId);
        const existingGrounds = existingVenue.grounds || [];
        const newGrounds = venue.grounds || [];
        // Combine and deduplicate grounds by ID
        const groundsMap = new Map();
        [...existingGrounds, ...newGrounds].forEach((ground: any) => {
          if (ground && ground.id) {
            groundsMap.set(ground.id, ground);
          }
        });
        existingVenue.grounds = Array.from(groundsMap.values());
      } else {
        // First occurrence of this venue
        venueMap.set(venueId, { ...venue });
      }
    }

    // Convert map back to array
    const deduplicatedVenues = Array.from(venueMap.values());

    // TODO: Calculate distance if lat/lng provided
    // For now, just return venues

    return {
      data: deduplicatedVenues,
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

    // Invalidate cache after updating venue
    await this.invalidateVenueCache(id);

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

    // Invalidate cache after deleting venue
    await this.invalidateVenueCache(id);

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

    // Invalidate cache after approving venue
    await this.invalidateVenueCache(id);

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

    // Invalidate cache after suspending venue
    await this.invalidateVenueCache(id);

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

    // Invalidate cache after activating venue
    await this.invalidateVenueCache(id);

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

    // Invalidate cache after deactivating venue
    await this.invalidateVenueCache(id);

    return updatedVenue;
  }

  /**
   * Upload a photo for a venue
   */
  async uploadPhoto(
    id: string,
    ownerId: string,
    tenantId: string,
    file: { buffer: Buffer; originalname: string; mimetype: string },
  ) {
    const supabase = this.supabaseService.getAdminClient();

    // Check if venue exists and belongs to owner's tenant
    const { data: venue, error: findError } = await supabase
      .from('venues')
      .select('owner_id, tenant_id, photos')
      .eq('id', id)
      .single();

    if (!venue || findError) {
      throw new NotFoundException('Venue not found');
    }

    if (venue.owner_id !== ownerId || venue.tenant_id !== tenantId) {
      throw new ForbiddenException('You do not have permission to upload photos for this venue');
    }

    // Generate unique filename
    const fileExt = file.originalname.split('.').pop();
    const fileName = `${id}/${Date.now()}.${fileExt}`;
    const bucketName = 'venue-photos';

    // Upload to Supabase Storage directly
    // The service role should bypass RLS, so we don't need to check bucket existence
    // If the bucket doesn't exist, the upload will fail with a clear error
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(fileName, file.buffer, {
        contentType: file.mimetype,
        upsert: false,
      });

    if (uploadError || !uploadData) {
      throw new Error(`Failed to upload photo: ${uploadError?.message}`);
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from(bucketName)
      .getPublicUrl(fileName);

    const photoUrl = urlData.publicUrl;

    // Update venue's photos array
    const currentPhotos = (venue.photos || []) as string[];
    const updatedPhotos = [...currentPhotos, photoUrl];

    const { data: updatedVenue, error: updateError } = await supabase
      .from('venues')
      .update({ photos: updatedPhotos })
      .eq('id', id)
      .select()
      .single();

    if (updateError || !updatedVenue) {
      throw new Error(`Failed to update venue photos: ${updateError?.message}`);
    }

    return {
      photoUrl,
      photos: updatedPhotos,
    };
  }

  /**
   * Create operating hours for a venue
   */
  async createOperatingHours(
    id: string,
    ownerId: string,
    tenantId: string,
    dto: CreateOperatingHoursDto,
  ) {
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
      throw new ForbiddenException(
        'You do not have permission to create operating hours for this venue',
      );
    }

    // Delete existing operating hours for this venue
    await supabase.from('operating_hours').delete().eq('venue_id', id);

    // Insert new operating hours
    const operatingHoursData = dto.operating_hours.map((oh) => ({
      venue_id: id,
      day_of_week: oh.day_of_week,
      open_time: oh.open_time,
      close_time: oh.close_time,
    }));

    const { data: createdHours, error: createError } = await supabase
      .from('operating_hours')
      .insert(operatingHoursData)
      .select();

    if (createError || !createdHours) {
      throw new Error(`Failed to create operating hours: ${createError?.message}`);
    }

    return createdHours;
  }
}

