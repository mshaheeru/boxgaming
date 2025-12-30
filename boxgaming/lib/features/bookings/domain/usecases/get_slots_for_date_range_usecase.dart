import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/day_slots_entity.dart';
import '../repositories/bookings_repository.dart';

class GetSlotsForDateRangeUseCase {
  final BookingsRepository repository;

  GetSlotsForDateRangeUseCase(this.repository);

  Future<Either<Failure, Map<String, DaySlotsEntity>>> call(
    String groundId,
    DateTime startDate,
    DateTime endDate,
    int duration,
  ) async {
    return await repository.getSlotsForDateRange(groundId, startDate, endDate, duration);
  }
}

