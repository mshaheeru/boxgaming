import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/venue_management_repository.dart';

class ActivateVenueUseCase {
  final VenueManagementRepository repository;

  ActivateVenueUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.activateVenue(id);
  }
}

