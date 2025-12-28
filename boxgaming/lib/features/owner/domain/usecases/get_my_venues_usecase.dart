import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/venue_management_repository.dart';
import '../../../venues/domain/entities/venue_entity.dart';

class GetMyVenuesUseCase {
  final VenueManagementRepository repository;

  GetMyVenuesUseCase(this.repository);

  Future<Either<Failure, List<VenueEntity>>> call() {
    return repository.getMyVenues();
  }
}

