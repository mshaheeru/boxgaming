import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
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
    return this.groundsService.create(venueId, req.user.id, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all grounds for a venue' })
  async findAllByVenue(@Param('venueId') venueId: string) {
    return this.groundsService.findAllByVenue(venueId);
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
    return this.groundsService.update(id, req.user.id, dto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'admin')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Delete ground (owner only)' })
  async remove(@Param('id') id: string, @Request() req) {
    return this.groundsService.remove(id, req.user.id);
  }
}
