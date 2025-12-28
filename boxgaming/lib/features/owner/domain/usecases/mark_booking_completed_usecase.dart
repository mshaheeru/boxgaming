import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/owner_repository.dart';

class MarkBookingCompletedUseCase {
  final OwnerRepository repository;

  MarkBookingCompletedUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId) async {
    return await repository.markBookingCompleted(bookingId);
  }
}



