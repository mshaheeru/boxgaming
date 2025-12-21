import { IsEnum, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PaymentGateway } from '../../common/enums/payment-gateway.enum';

export class InitiatePaymentDto {
  @ApiProperty({ enum: PaymentGateway, example: 'payfast' })
  @IsEnum(PaymentGateway)
  @IsNotEmpty()
  paymentMethod: PaymentGateway;
}

