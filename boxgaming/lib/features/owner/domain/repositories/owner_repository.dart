import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_entity.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

abstract class OwnerRepository {
  Future<Either<Failure, DashboardEntity>> getTodayBookings();
  
  Future<Either<Failure, List<BookingEntity>>> getAllBookings();
  
  Future<Either<Failure, void>> markBookingStarted(String bookingId);
  
  Future<Either<Failure, void>> markBookingCompleted(String bookingId);
}

