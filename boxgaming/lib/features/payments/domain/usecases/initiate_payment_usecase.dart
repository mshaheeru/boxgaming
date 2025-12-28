import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_entity.dart';
import '../repositories/payments_repository.dart';

class InitiatePaymentUseCase {
  final PaymentsRepository repository;

  InitiatePaymentUseCase(this.repository);

  Future<Either<Failure, PaymentEntity>> call(
    String bookingId,
    PaymentGateway gateway,
  ) async {
    return await repository.initiatePayment(bookingId, gateway);
  }
}



