import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/venue_management_repository.dart';

class DeactivateVenueUseCase {
  final VenueManagementRepository repository;

  DeactivateVenueUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deactivateVenue(id);
  }
}

