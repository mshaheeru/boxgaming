import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/bookings_repository.dart';

class GetBookingDetailsUseCase {
  final BookingsRepository repository;

  GetBookingDetailsUseCase(this.repository);

  Future<Either<Failure, BookingEntity>> call(String bookingId) async {
    return await repository.getBookingDetails(bookingId);
  }
}


