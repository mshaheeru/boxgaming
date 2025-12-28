import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/venue_management_repository.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import '../../../venues/dto/create_venue_dto.dart';

class CreateVenueUseCase {
  final VenueManagementRepository repository;

  CreateVenueUseCase(this.repository);

  Future<Either<Failure, VenueEntity>> call(CreateVenueDto dto) {
    return repository.createVenue(dto);
  }
}

