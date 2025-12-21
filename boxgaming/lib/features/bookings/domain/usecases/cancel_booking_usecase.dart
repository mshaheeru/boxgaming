import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/bookings_repository.dart';

class CancelBookingUseCase {
  final BookingsRepository repository;

  CancelBookingUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId) async {
    return await repository.cancelBooking(bookingId);
  }
}


