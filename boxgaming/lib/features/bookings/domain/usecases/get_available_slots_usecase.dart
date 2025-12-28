import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/slot_entity.dart';
import '../repositories/bookings_repository.dart';

class GetAvailableSlotsUseCase {
  final BookingsRepository repository;

  GetAvailableSlotsUseCase(this.repository);

  Future<Either<Failure, List<SlotEntity>>> call(
    String groundId,
    DateTime date,
    int duration,
  ) async {
    return await repository.getAvailableSlots(groundId, date, duration);
  }
}



