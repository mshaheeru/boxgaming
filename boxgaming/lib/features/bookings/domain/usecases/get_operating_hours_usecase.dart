import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/operating_hours_entity.dart';
import '../repositories/bookings_repository.dart';

class GetOperatingHoursUseCase {
  final BookingsRepository repository;

  GetOperatingHoursUseCase(this.repository);

  Future<Either<Failure, List<OperatingHoursEntity>>> call(
    String venueId,
    String groundId,
  ) async {
    return await repository.getOperatingHours(venueId, groundId);
  }
}

