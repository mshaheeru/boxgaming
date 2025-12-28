import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { VenuesService } from './venues.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { VenueQueryDto } from './dto/venue-query.dto';

@ApiTags('venues')
@Controller('venues')
export class VenuesController {
  constructor(private readonly venuesService: VenuesService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new venue (owner only)' })
  async create(@Request() req, @Body() dto: CreateVenueDto) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.venuesService.create(req.user.id, tenantId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all venues with filters' })
  async findAll(@Query() query: VenueQueryDto, @Request() req?: any) {
    // If user is owner, filter by their tenant_id
    // If customer or no auth, show all active venues
    const tenantId = req?.user?.tenant_id || null;
    return this.venuesService.findAll(query, tenantId);
  }

  @Get('my-venues')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get owner\'s venues (filtered by tenant)' })
  async findMyVenues(@Request() req) {
    const tenantId = req.user.tenant_id;
    if (!tenantId) {
      throw new Error('Owner must have a tenant');
    }
    return this.venuesService.findMyVenues(req.user.id, tenantId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get venue by ID' })
  async findOne(@Param('id') id: string, @Request() req?: any) {
    const tenantId = req?.user?.tenant_id || null;
    const role = req?.user?.role || null;
    return this.venuesService.findOne(id, tenantId, role);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update venue (owner only)' })
  async update(
    @Param('id') id: string,
    @Request() req,
    @Body() dto: UpdateVenueDto,
  ) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.venuesService.update(id, req.user.id, tenantId, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete venue (owner only)' })
  async remove(@Param('id') id: string, @Request() req) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.venuesService.remove(id, req.user.id, tenantId);
  }

  @Put(':id/approve')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Approve venue (admin only)' })
  async approve(@Param('id') id: string) {
    return this.venuesService.approve(id);
  }

  @Put(':id/suspend')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Suspend venue (admin only)' })
  async suspend(@Param('id') id: string) {
    return this.venuesService.suspend(id);
  }

  @Put(':id/activate')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Activate venue (owner only, tenant-scoped)' })
  async activate(@Param('id') id: string, @Request() req) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.venuesService.activate(id, req.user.id, tenantId);
  }

  @Put(':id/deactivate')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Deactivate venue (owner only, tenant-scoped)' })
  async deactivate(@Param('id') id: string, @Request() req) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.venuesService.deactivate(id, req.user.id, tenantId);
  }
}
