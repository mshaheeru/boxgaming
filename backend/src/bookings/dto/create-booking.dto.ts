import { IsString, IsNotEmpty, IsDateString, IsInt, IsIn } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateBookingDto {
  @ApiProperty({ example: 'uuid-of-ground' })
  @IsString()
  @IsNotEmpty()
  groundId: string;

  @ApiProperty({ example: '2024-12-25' })
  @IsDateString()
  @IsNotEmpty()
  bookingDate: string;

  @ApiProperty({ example: '10:00' })
  @IsString()
  @IsNotEmpty()
  startTime: string;

  @ApiProperty({ example: 2, enum: [2, 3] })
  @IsInt()
  @IsIn([2, 3])
  durationHours: 2 | 3;
}

