import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsArray,
  IsNumber,
  IsDecimal,
  ValidateNested,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class CreateVenueDto {
  @ApiProperty({ example: 'Sports Complex Karachi' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: '123 Main Street, Karachi', required: false })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiProperty({ example: 'Karachi', required: false })
  @IsString()
  @IsOptional()
  city?: string;

  @ApiProperty({ example: 24.8607, required: false })
  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  lat?: number;

  @ApiProperty({ example: 67.0011, required: false })
  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  lng?: number;

  @ApiProperty({ example: 'Modern sports facility', required: false })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({
    example: ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
    required: false,
  })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  photos?: string[];
}

