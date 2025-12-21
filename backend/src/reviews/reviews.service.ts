import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
  constructor(private supabaseService: SupabaseService) {}

  async create(customerId: string, dto: CreateReviewDto) {
    const supabase = this.supabaseService.getAdminClient();
    
    // Verify booking exists and belongs to customer
    const { data: booking, error: bookingError } = await supabase
      .from('bookings')
      .select('*, venue:venues!bookings_venue_id_fkey(*)')
      .eq('id', dto.bookingId)
      .single();

    if (!booking || bookingError) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.customer_id !== customerId) {
      throw new BadRequestException('You can only review your own bookings');
    }

    if (booking.status !== 'completed') {
      throw new BadRequestException('You can only review completed bookings');
    }

    // Check if review already exists
    const { data: existingReview } = await supabase
      .from('reviews')
      .select('id')
      .eq('booking_id', dto.bookingId)
      .single();

    if (existingReview) {
      throw new BadRequestException('Review already exists for this booking');
    }

    // Create review
    const { data: review, error: reviewError } = await supabase
      .from('reviews')
      .insert({
        booking_id: dto.bookingId,
        customer_id: customerId,
        venue_id: booking.venue_id,
        rating: dto.rating,
        comment: dto.comment,
      })
      .select(`
        *,
        customer:users!reviews_customer_id_fkey(id, name)
      `)
      .single();

    if (reviewError || !review) {
      throw new Error(`Failed to create review: ${reviewError?.message}`);
    }

    // Update venue rating
    await this.updateVenueRating(booking.venue_id);

    return review;
  }

  private async updateVenueRating(venueId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: reviews } = await supabase
      .from('reviews')
      .select('rating')
      .eq('venue_id', venueId);

    if (!reviews || reviews.length === 0) {
      return;
    }

    const averageRating =
      reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length;

    await supabase
      .from('venues')
      .update({ rating: averageRating })
      .eq('id', venueId);
  }

  async findByVenue(venueId: string) {
    const supabase = this.supabaseService.getAdminClient();
    
    const { data: reviews, error } = await supabase
      .from('reviews')
      .select(`
        *,
        customer:users!reviews_customer_id_fkey(id, name)
      `)
      .eq('venue_id', venueId)
      .order('created_at', { ascending: false });

    if (error) {
      throw new Error(`Failed to fetch reviews: ${error.message}`);
    }

    return reviews || [];
  }
}

