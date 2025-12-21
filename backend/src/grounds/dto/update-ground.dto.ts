import { IsString, IsOptional, IsEnum, IsNumber, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';
import { SportType } from '../../common/enums/sport-type.enum';
import { GroundSize } from '../../common/enums/ground-size.enum';

export class UpdateGroundDto {
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({ enum: SportType, required: false })
  @IsEnum(SportType)
  @IsOptional()
  sportType?: SportType;

  @ApiProperty({ enum: GroundSize, required: false })
  @IsEnum(GroundSize)
  @IsOptional()
  size?: GroundSize;

  @ApiProperty({ required: false })
  @IsNumber()
  @Type(() => Number)
  @IsOptional()
  price2hr?: number;

  @ApiProperty({ required: false })
  @IsNumber()
  @Type(() => Number)
  @IsOptional()
  price3hr?: number;

  @ApiProperty({ required: false })
  @IsBoolean()
  @Type(() => Boolean)
  @IsOptional()
  isActive?: boolean;
}

