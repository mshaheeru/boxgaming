import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateGroundDto } from './dto/create-ground.dto';
import { UpdateGroundDto } from './dto/update-ground.dto';
import { VenuesService } from '../venues/venues.service';

@Injectable()
export class GroundsService {
  constructor(
    private supabaseService: SupabaseService,
    private venuesService: VenuesService,
  ) {}

  async create(venueId: string, ownerId: string, dto: CreateGroundDto) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Verify venue ownership
    const { data: venue, error: venueError } = await supabase
      .from('venues')
      .select('owner_id')
      .eq('id', venueId)
      .single();

    if (!venue || venueError) {
      throw new NotFoundException('Venue not found');
    }

    if (venue.owner_id !== ownerId) {
      throw new ForbiddenException('You do not have permission to add grounds to this venue');
    }

    const { data: ground, error } = await supabase
      .from('grounds')
      .insert({
        ...dto,
        venue_id: venueId,
        sport_type: dto.sportType,
        price_2hr: dto.price2hr,
        price_3hr: dto.price3hr,
      })
      .select()
      .single();

    if (error || !ground) {
      throw new Error(`Failed to create ground: ${error?.message}`);
    }

    return {
      ...ground,
      venueId: ground.venue_id,
      sportType: ground.sport_type,
      price2hr: ground.price_2hr,
      price3hr: ground.price_3hr,
      isActive: ground.is_active,
    };
  }

  async findAllByVenue(venueId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: grounds, error } = await supabase
      .from('grounds')
      .select(`
        *,
        venue:venues!grounds_venue_id_fkey(id, name)
      `)
      .eq('venue_id', venueId)
      .eq('is_active', true);

    if (error) {
      throw new Error(`Failed to fetch grounds: ${error.message}`);
    }

    return (grounds || []).map(ground => ({
      ...ground,
      venueId: ground.venue_id,
      sportType: ground.sport_type,
      price2hr: ground.price_2hr,
      price3hr: ground.price_3hr,
      isActive: ground.is_active,
    }));
  }

  async findOne(id: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: ground, error } = await supabase
      .from('grounds')
      .select(`
        *,
        venue:venues!grounds_venue_id_fkey(id, name, owner_id)
      `)
      .eq('id', id)
      .single();

    if (!ground || error) {
      throw new NotFoundException('Ground not found');
    }

    return {
      ...ground,
      venueId: ground.venue_id,
      sportType: ground.sport_type,
      price2hr: ground.price_2hr,
      price3hr: ground.price_3hr,
      isActive: ground.is_active,
      venue: {
        ...ground.venue,
        ownerId: ground.venue.owner_id,
      },
    };
  }

  async update(id: string, ownerId: string, dto: UpdateGroundDto) {
    const ground = await this.findOne(id);

    if (ground.venue.owner_id !== ownerId) {
      throw new ForbiddenException('You do not have permission to update this ground');
    }

    const supabase = this.supabaseService.getAdminClient();
    const updateData: any = { ...dto };
    
    if (dto.sportType) updateData.sport_type = dto.sportType;
    if (dto.price2hr !== undefined) updateData.price_2hr = dto.price2hr;
    if (dto.price3hr !== undefined) updateData.price_3hr = dto.price3hr;
    if (dto.isActive !== undefined) updateData.is_active = dto.isActive;
    
    delete updateData.sportType;
    delete updateData.price2hr;
    delete updateData.price3hr;
    delete updateData.isActive;

    const { data: updatedGround, error } = await supabase
      .from('grounds')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error || !updatedGround) {
      throw new Error(`Failed to update ground: ${error?.message}`);
    }

    return {
      ...updatedGround,
      venueId: updatedGround.venue_id,
      sportType: updatedGround.sport_type,
      price2hr: updatedGround.price_2hr,
      price3hr: updatedGround.price_3hr,
      isActive: updatedGround.is_active,
    };
  }

  async remove(id: string, ownerId: string) {
    const ground = await this.findOne(id);

    if (ground.venue.owner_id !== ownerId) {
      throw new ForbiddenException('You do not have permission to delete this ground');
    }

    // Soft delete
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: updatedGround, error } = await supabase
      .from('grounds')
      .update({ is_active: false })
      .eq('id', id)
      .select()
      .single();

    if (error || !updatedGround) {
      throw new Error(`Failed to remove ground: ${error?.message}`);
    }

    return {
      ...updatedGround,
      venueId: updatedGround.venue_id,
      sportType: updatedGround.sport_type,
      price2hr: updatedGround.price_2hr,
      price3hr: updatedGround.price_3hr,
      isActive: updatedGround.is_active,
    };
  }
}

