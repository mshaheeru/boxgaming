import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment_entity.dart';

abstract class PaymentsRepository {
  Future<Either<Failure, PaymentEntity>> initiatePayment(
    String bookingId,
    PaymentGateway gateway,
  );
}


