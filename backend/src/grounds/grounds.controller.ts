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
import { GroundsService } from './grounds.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CreateGroundDto } from './dto/create-ground.dto';
import { UpdateGroundDto } from './dto/update-ground.dto';
import { CreateOperatingHoursDto } from '../venues/dto/create-operating-hours.dto';

@ApiTags('grounds')
@Controller('venues/:venueId/grounds')
export class GroundsController {
  constructor(private readonly groundsService: GroundsService) {}

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new ground (owner only)' })
  async create(
    @Param('venueId') venueId: string,
    @Request() req,
    @Body() dto: CreateGroundDto,
  ) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.groundsService.create(venueId, req.user.id, tenantId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all grounds for a venue' })
  async findAllByVenue(
    @Param('venueId') venueId: string,
    @Query('includeInactive') includeInactive?: string,
  ) {
    const includeInactiveBool = includeInactive === 'true';
    return this.groundsService.findAllByVenue(venueId, includeInactiveBool);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get ground by ID' })
  async findOne(@Param('id') id: string) {
    return this.groundsService.findOne(id);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update ground (owner only)' })
  async update(
    @Param('id') id: string,
    @Request() req,
    @Body() dto: UpdateGroundDto,
  ) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.groundsService.update(id, req.user.id, tenantId, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete ground (owner only)' })
  async remove(@Param('id') id: string, @Request() req) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.groundsService.remove(id, req.user.id, tenantId);
  }

  @Post(':id/operating-hours')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create/Update operating hours for a ground (owner only)' })
  async createOperatingHours(
    @Param('id') id: string,
    @Request() req,
    @Body() dto: CreateOperatingHoursDto,
  ) {
    const tenantId = req.user.tenant_id;
    if (!tenantId && req.user.role === 'owner') {
      throw new Error('Owner must have a tenant');
    }
    return this.groundsService.createOperatingHours(id, req.user.id, tenantId, dto);
  }

  @Get(':id/operating-hours')
  @ApiOperation({ summary: 'Get operating hours for a ground' })
  async getOperatingHours(@Param('id') id: string) {
    return this.groundsService.getOperatingHours(id);
  }
}
