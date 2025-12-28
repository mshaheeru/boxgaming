import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/owner_repository.dart';

class GetTodayBookingsUseCase {
  final OwnerRepository repository;

  GetTodayBookingsUseCase(this.repository);

  Future<Either<Failure, DashboardEntity>> call() async {
    return await repository.getTodayBookings();
  }
}



