import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../repositories/owner_repository.dart';

class GetAllBookingsUseCase {
  final OwnerRepository repository;

  GetAllBookingsUseCase(this.repository);

  Future<Either<Failure, List<BookingEntity>>> call() async {
    return await repository.getAllBookings();
  }
}

