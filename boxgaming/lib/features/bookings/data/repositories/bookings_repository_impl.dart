import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/slot_entity.dart';
import '../../domain/entities/operating_hours_entity.dart';
import '../../domain/entities/day_slots_entity.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/bookings_remote_datasource.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final BookingsRemoteDataSource remoteDataSource;

  BookingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SlotEntity>>> getAvailableSlots(
    String groundId,
    DateTime date,
    int duration,
  ) async {
    try {
      final slots = await remoteDataSource.getAvailableSlots(groundId, date, duration);
      return Right(slots.map((s) => s.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<OperatingHoursEntity>>> getOperatingHours(
    String venueId,
    String groundId,
  ) async {
    try {
      final operatingHours = await remoteDataSource.getOperatingHours(venueId, groundId);
      return Right(operatingHours.map((oh) => oh.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, DaySlotsEntity>>> getSlotsForDateRange(
    String groundId,
    DateTime startDate,
    DateTime endDate,
    int duration,
  ) async {
    try {
      final slotsByDate = await remoteDataSource.getSlotsForDateRange(
        groundId,
        startDate,
        endDate,
        duration,
      );
      return Right(slotsByDate.map((key, value) => MapEntry(key, value.toEntity())));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required String groundId,
    required DateTime bookingDate,
    required String startTime,
    required int durationHours,
  }) async {
    try {
      final booking = await remoteDataSource.createBooking(
        groundId: groundId,
        bookingDate: bookingDate,
        startTime: startTime,
        durationHours: durationHours,
      );
      return Right(booking.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BookingEntity>>> getMyBookings({
    required String type,
  }) async {
    try {
      final bookings = await remoteDataSource.getMyBookings(type);
      return Right(bookings.map((b) => b.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingDetails(String bookingId) async {
    try {
      final booking = await remoteDataSource.getBookingDetails(bookingId);
      return Right(booking.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(String bookingId) async {
    try {
      await remoteDataSource.cancelBooking(bookingId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}



