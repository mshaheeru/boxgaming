import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/owner_repository.dart';

class MarkBookingStartedUseCase {
  final OwnerRepository repository;

  MarkBookingStartedUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId) async {
    return await repository.markBookingStarted(bookingId);
  }
}


