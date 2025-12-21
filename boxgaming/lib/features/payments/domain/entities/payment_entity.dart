import 'package:equatable/equatable.dart';

enum PaymentGateway {
  jazzcash,
  easypaisa,
  card,
  payfast,
}

class PaymentEntity extends Equatable {
  final String id;
  final String bookingId;
  final double amount;
  final PaymentGateway gateway;
  final String? paymentUrl;
  final String? transactionId;

  const PaymentEntity({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.gateway,
    this.paymentUrl,
    this.transactionId,
  });

  @override
  List<Object?> get props => [
        id,
        bookingId,
        amount,
        gateway,
        paymentUrl,
        transactionId,
      ];
}


