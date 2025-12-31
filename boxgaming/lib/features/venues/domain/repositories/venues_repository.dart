import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/venue_entity.dart';
import '../entities/ground_entity.dart';

abstract class VenuesRepository {
  Future<Either<Failure, List<VenueEntity>>> getVenues({
    String? search,
    String? city,
    SportType? sportType,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  });
  
  Future<Either<Failure, VenueEntity>> getVenueDetails(String id, {bool forceRefresh = false});
  
  Future<Either<Failure, List<GroundEntity>>> getVenueGrounds(String venueId);
}



