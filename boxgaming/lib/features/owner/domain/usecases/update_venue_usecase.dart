import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/venue_management_repository.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import '../../../venues/dto/update_venue_dto.dart';

class UpdateVenueUseCase {
  final VenueManagementRepository repository;

  UpdateVenueUseCase(this.repository);

  Future<Either<Failure, VenueEntity>> call(String id, UpdateVenueDto dto) {
    return repository.updateVenue(id, dto);
  }
}

