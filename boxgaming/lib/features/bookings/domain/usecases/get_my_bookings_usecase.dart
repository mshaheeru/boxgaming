import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/bookings_repository.dart';

class GetMyBookingsUseCase {
  final BookingsRepository repository;

  GetMyBookingsUseCase(this.repository);

  Future<Either<Failure, List<BookingEntity>>> call(String type) async {
    return await repository.getMyBookings(type: type);
  }
}


