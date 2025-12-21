import { Controller, Get, Put, Body, Param, UseGuards, Request, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PayoutsService } from './payouts.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { SupabaseService } from '../supabase/supabase.service';
import { PaginationDto } from '../common/dto/pagination.dto';

@ApiTags('payouts')
@Controller('payouts')
export class PayoutsController {
  constructor(
    private readonly payoutsService: PayoutsService,
    private readonly supabaseService: SupabaseService,
  ) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all payouts (admin only)' })
  async findAll(@Query() query: PaginationDto) {
    const skip = query.skip || 0;
    const take = query.take || 10;
    const supabase = this.supabaseService.getAdminClient();

    const [payoutsResult, countResult] = await Promise.all([
      supabase
        .from('payouts')
        .select(`
          *,
          owner:users!payouts_owner_id_fkey(id, name, phone)
        `)
        .order('period_end', { ascending: false })
        .range(skip, skip + take - 1),
      supabase
        .from('payouts')
        .select('*', { count: 'exact', head: true }),
    ]);

    if (payoutsResult.error) {
      throw new Error(`Failed to fetch payouts: ${payoutsResult.error.message}`);
    }

    return {
      data: payoutsResult.data || [],
      meta: {
        total: countResult.count || 0,
        page: query.page || 1,
        limit: query.limit || 10,
        totalPages: Math.ceil((countResult.count || 0) / (query.limit || 10)),
      },
    };
  }

  @Get('my-payouts')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current owner payouts' })
  async getMyPayouts(@Request() req) {
    return this.payoutsService.getOwnerPayouts(req.user.id);
  }

  @Put(':id/mark-paid')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark payout as paid (admin only)' })
  async markPaid(
    @Param('id') id: string,
    @Body('bankReference') bankReference: string,
  ) {
    return this.payoutsService.markPaid(id, bankReference);
  }
}
