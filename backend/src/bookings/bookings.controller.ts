import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { SlotService } from './slot.service';
import { CancellationService } from './cancellation.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CreateBookingDto } from './dto/create-booking.dto';
import { SupabaseService } from '../supabase/supabase.service';
import { PaginationDto } from '../common/dto/pagination.dto';

@ApiTags('bookings')
@Controller('bookings')
export class BookingsController {
  constructor(
    private readonly bookingsService: BookingsService,
    private readonly slotService: SlotService,
    private readonly cancellationService: CancellationService,
    private readonly supabaseService: SupabaseService,
  ) {}

  @Get('grounds/:groundId/slots')
  @ApiOperation({ summary: 'Get available slots for a ground' })
  async getSlots(
    @Param('groundId') groundId: string,
    @Query('date') date: string,
    @Query('duration') duration: string,
  ) {
    const dateObj = new Date(date);
    const durationNum = parseInt(duration, 10) as 2 | 3;
    return this.slotService.getAvailableSlots(groundId, dateObj, durationNum);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new booking (pending payment)' })
  async create(@Request() req, @Body() dto: CreateBookingDto) {
    return this.bookingsService.createPendingBooking(req.user.id, dto);
  }

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all bookings (admin only)' })
  async findAll(@Query() query: PaginationDto) {
    const skip = query.skip || 0;
    const take = query.take || 10;
    const supabase = this.supabaseService.getAdminClient();

    const [bookingsResult, countResult] = await Promise.all([
      supabase
        .from('bookings')
        .select(`
          *,
          ground:grounds!bookings_ground_id_fkey(
            *,
            venue:venues!grounds_venue_id_fkey(id, name)
          ),
          customer:users!bookings_customer_id_fkey(id, name, phone)
        `)
        .order('created_at', { ascending: false })
        .range(skip, skip + take - 1),
      supabase
        .from('bookings')
        .select('*', { count: 'exact', head: true }),
    ]);

    if (bookingsResult.error) {
      throw new Error(`Failed to fetch bookings: ${bookingsResult.error.message}`);
    }

    return {
      data: bookingsResult.data || [],
      meta: {
        total: countResult.count || 0,
        page: query.page || 1,
        limit: query.limit || 10,
        totalPages: Math.ceil((countResult.count || 0) / (query.limit || 10)),
      },
    };
  }

  @Get('my-bookings')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current user bookings' })
  async getMyBookings(
    @Request() req,
    @Query('type') type: 'upcoming' | 'past' = 'upcoming',
  ) {
    return this.bookingsService.getMyBookings(req.user.id, type);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get booking by ID' })
  async findOne(@Param('id') id: string, @Request() req) {
    return this.bookingsService.findOne(id, req.user.id);
  }

  @Post(':id/cancel')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel a booking' })
  async cancel(@Param('id') id: string, @Request() req) {
    return this.cancellationService.cancelBooking(id, req.user.id);
  }

  @Post(':id/start')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark booking as started (owner only)' })
  async markStarted(@Param('id') id: string, @Request() req) {
    return this.bookingsService.markStarted(id, req.user.id);
  }

  @Post(':id/complete')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark booking as completed (owner only)' })
  async markCompleted(@Param('id') id: string, @Request() req) {
    return this.bookingsService.markCompleted(id, req.user.id);
  }
}
