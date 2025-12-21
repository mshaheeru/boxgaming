import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entity.dart';

abstract class PaymentsEvent extends Equatable {
  const PaymentsEvent();

  @override
  List<Object> get props => [];
}

class InitiatePaymentEvent extends PaymentsEvent {
  final String bookingId;
  final PaymentGateway gateway;

  const InitiatePaymentEvent({
    required this.bookingId,
    required this.gateway,
  });

  @override
  List<Object> get props => [bookingId, gateway];
}


