import { IsString, IsNotEmpty, IsEnum, IsNumber, IsDecimal } from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';
import { SportType } from '../../common/enums/sport-type.enum';
import { GroundSize } from '../../common/enums/ground-size.enum';

export class CreateGroundDto {
  @ApiProperty({ example: 'Court A' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ enum: SportType, example: 'badminton' })
  @IsEnum(SportType)
  sportType: SportType;

  @ApiProperty({ enum: GroundSize, example: 'medium' })
  @IsEnum(GroundSize)
  size: GroundSize;

  @ApiProperty({ example: 2000.00 })
  @IsNumber()
  @Type(() => Number)
  price2hr: number;

  @ApiProperty({ example: 2800.00 })
  @IsNumber()
  @Type(() => Number)
  price3hr: number;
}

