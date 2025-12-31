import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/venue_entity.dart';
import '../repositories/venues_repository.dart';

class GetVenuesUseCase {
  final VenuesRepository repository;

  GetVenuesUseCase(this.repository);

  Future<Either<Failure, List<VenueEntity>>> call({
    String? city,
    SportType? sportType,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    return await repository.getVenues(
      city: city,
      sportType: sportType,
      lat: lat,
      lng: lng,
      page: page,
      limit: limit,
      forceRefresh: forceRefresh,
    );
  }
}



