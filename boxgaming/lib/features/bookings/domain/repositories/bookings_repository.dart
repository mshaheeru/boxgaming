import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/booking_entity.dart';
import '../entities/slot_entity.dart';
import '../entities/operating_hours_entity.dart';
import '../entities/day_slots_entity.dart';

abstract class BookingsRepository {
  Future<Either<Failure, List<SlotEntity>>> getAvailableSlots(
    String groundId,
    DateTime date,
    int duration,
  );
  
  Future<Either<Failure, List<OperatingHoursEntity>>> getOperatingHours(
    String venueId,
    String groundId,
  );
  
  Future<Either<Failure, Map<String, DaySlotsEntity>>> getSlotsForDateRange(
    String groundId,
    DateTime startDate,
    DateTime endDate,
    int duration,
  );
  
  Future<Either<Failure, BookingEntity>> createBooking({
    required String groundId,
    required DateTime bookingDate,
    required String startTime,
    required int durationHours,
  });
  
  Future<Either<Failure, List<BookingEntity>>> getMyBookings({
    required String type, // 'upcoming' or 'past'
  });
  
  Future<Either<Failure, BookingEntity>> getBookingDetails(String bookingId);
  
  Future<Either<Failure, void>> cancelBooking(String bookingId);
}



