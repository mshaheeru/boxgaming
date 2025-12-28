import { IsString, IsEmail, IsOptional, MinLength, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateTenantDto {
  @ApiProperty({ description: 'Owner email address' })
  @IsEmail()
  email: string;

  @ApiProperty({ description: 'Tenant/business name (e.g., "indoormania")' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  tenantName: string;

  @ApiPropertyOptional({ description: 'Temporary password (auto-generated if not provided)' })
  @IsOptional()
  @IsString()
  @MinLength(8)
  temporaryPassword?: string;

  @ApiPropertyOptional({ description: 'Owner full name' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ description: 'Owner phone number' })
  @IsOptional()
  @IsString()
  phone?: string;
}

