import { IsArray, ValidateNested, IsInt, Min, Max, IsString, Matches } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

class OperatingHourDto {
  @ApiProperty({ example: 0, description: 'Day of week (0=Sunday, 6=Saturday)' })
  @IsInt()
  @Min(0)
  @Max(6)
  day_of_week: number;

  @ApiProperty({ example: '09:00', description: 'Opening time in HH:mm format' })
  @IsString()
  @Matches(/^([0-1][0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'open_time must be in HH:mm format',
  })
  open_time: string;

  @ApiProperty({ example: '22:00', description: 'Closing time in HH:mm format' })
  @IsString()
  @Matches(/^([0-1][0-9]|2[0-3]):[0-5][0-9]$/, {
    message: 'close_time must be in HH:mm format',
  })
  close_time: string;
}

export class CreateOperatingHoursDto {
  @ApiProperty({ type: [OperatingHourDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OperatingHourDto)
  operating_hours: OperatingHourDto[];
}

