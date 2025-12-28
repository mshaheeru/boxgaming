import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import '../../../venues/dto/create_venue_dto.dart';
import '../../../venues/dto/update_venue_dto.dart';

abstract class VenueManagementRepository {
  Future<Either<Failure, List<VenueEntity>>> getMyVenues();
  Future<Either<Failure, VenueEntity>> createVenue(CreateVenueDto dto);
  Future<Either<Failure, VenueEntity>> updateVenue(
    String id,
    UpdateVenueDto dto,
  );
  Future<Either<Failure, void>> activateVenue(String id);
  Future<Either<Failure, void>> deactivateVenue(String id);
}

