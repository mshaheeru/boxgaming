import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/bookings_repository.dart';

class CreateBookingUseCase {
  final BookingsRepository repository;

  CreateBookingUseCase(this.repository);

  Future<Either<Failure, BookingEntity>> call({
    required String groundId,
    required DateTime bookingDate,
    required String startTime,
    required int durationHours,
    required String paymentMethod,
  }) async {
    return await repository.createBooking(
      groundId: groundId,
      bookingDate: bookingDate,
      startTime: startTime,
      durationHours: durationHours,
      paymentMethod: paymentMethod,
    );
  }
}



