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
  BadRequestException,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { TenantsService } from './tenants.service';
import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantDto } from './dto/update-tenant.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('tenants')
@Controller('tenants')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class TenantsController {
  constructor(private readonly tenantsService: TenantsService) {}

  @Post()
  @Roles('admin')
  @ApiOperation({ summary: 'Create a new tenant and owner account (admin only)' })
  @ApiResponse({ status: 201, description: 'Tenant and owner created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 409, description: 'Tenant or email already exists' })
  async create(@Body() dto: CreateTenantDto) {
    return this.tenantsService.createTenant(dto);
  }

  @Get()
  @Roles('admin')
  @ApiOperation({ summary: 'Get all tenants (admin only)' })
  async findAll() {
    return this.tenantsService.findAll();
  }

  @Get('my-tenant')
  @Roles('owner')
  @ApiOperation({ summary: 'Get owner\'s tenant' })
  async getMyTenant(@Request() req) {
    return this.tenantsService.getMyTenant(req.user.id);
  }

  @Get(':id')
  @Roles('admin')
  @ApiOperation({ summary: 'Get tenant by ID (admin only)' })
  async findOne(@Param('id') id: string) {
    return this.tenantsService.findOne(id);
  }

  @Put(':id')
  @Roles('admin')
  @ApiOperation({ summary: 'Update tenant (admin only)' })
  async update(@Param('id') id: string, @Body() dto: UpdateTenantDto) {
    return this.tenantsService.update(id, dto);
  }

  @Delete(':id')
  @Roles('admin')
  @ApiOperation({ summary: 'Delete tenant (admin only) - soft delete' })
  async remove(@Param('id') id: string) {
    await this.tenantsService.remove(id);
    return { message: 'Tenant deleted successfully' };
  }

  @Post(':tenantId/owner/reset-password')
  @Roles('admin')
  @ApiOperation({ summary: 'Reset owner password - generates new temporary password (admin only)' })
  @ApiResponse({ status: 200, description: 'Password reset successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  async resetOwnerPassword(@Param('tenantId') tenantId: string) {
    // Get owner_id from tenant
    const tenant = await this.tenantsService.findOne(tenantId);
    if (!tenant || !tenant.owner_id) {
      throw new BadRequestException('Tenant or owner not found');
    }
    return this.tenantsService.resetOwnerPassword(tenant.owner_id);
  }
}

