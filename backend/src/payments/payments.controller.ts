import { Controller, Post, Body, Param, UseGuards, Request, Headers } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';

@ApiTags('payments')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('initiate/:bookingId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Initiate payment for a booking' })
  async initiatePayment(
    @Param('bookingId') bookingId: string,
    @Request() req,
    @Body() dto: InitiatePaymentDto,
  ) {
    return this.paymentsService.initiatePayment(bookingId, dto);
  }

  @Post('webhooks/payment')
  @ApiOperation({ summary: 'Payment webhook from gateway' })
  async handleWebhook(@Body() payload: any, @Headers('x-payfast-signature') signature: string) {
    return this.paymentsService.handleWebhook(payload, signature);
  }
}

