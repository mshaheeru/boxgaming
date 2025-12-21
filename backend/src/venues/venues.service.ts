import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { VenueQueryDto } from './dto/venue-query.dto';

@Injectable()
export class VenuesService {
  constructor(private supabaseService: SupabaseService) {}

  async create(ownerId: string, dto: CreateVenueDto) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: venue, error } = await supabase
      .from('venues')
      .insert({
        ...dto,
        owner_id: ownerId,
        status: 'pending', // Requires admin approval
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
      createdAt: venue.created_at,
      owner: venue.owner,
    };
  }

  async findAll(query: VenueQueryDto) {
    const { city, sportType, lat, lng, page = 1, limit = 10 } = query;
    const supabase = this.supabaseService.getAdminClient();
    const skip = (page - 1) * limit;

    let queryBuilder = supabase
      .from('venues')
      .select(`
        *,
        grounds!inner(id, name, sport_type, size, price_2hr, price_3hr),
        reviews(count)
      `)
      .eq('status', 'active')
      .eq('grounds.is_active', true);

    if (city) {
      queryBuilder = queryBuilder.eq('city', city);
    }

    if (sportType) {
      queryBuilder = queryBuilder.eq('grounds.sport_type', sportType);
    }

    // Get total count
    let countQuery = supabase
      .from('venues')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'active');

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

  async findOne(id: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: venue, error } = await supabase
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
      .eq('id', id)
      .single();

    if (!venue || error) {
      throw new NotFoundException('Venue not found');
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

  async update(id: string, ownerId: string, dto: UpdateVenueDto) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Check if venue exists and belongs to owner
    const { data: venue, error: findError } = await supabase
      .from('venues')
      .select('owner_id')
      .eq('id', id)
      .single();

    if (!venue || findError) {
      throw new NotFoundException('Venue not found');
    }

    if (venue.owner_id !== ownerId) {
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
}

