import 'package:equatable/equatable.dart';
import '../../domain/entities/payment_entity.dart';

abstract class PaymentsState extends Equatable {
  const PaymentsState();

  @override
  List<Object> get props => [];
}

class PaymentsInitial extends PaymentsState {}

class PaymentsLoading extends PaymentsState {}

class PaymentInitiated extends PaymentsState {
  final PaymentEntity payment;
  const PaymentInitiated(this.payment);

  @override
  List<Object> get props => [payment];
}

class PaymentsError extends PaymentsState {
  final String message;
  const PaymentsError(this.message);

  @override
  List<Object> get props => [message];
}



