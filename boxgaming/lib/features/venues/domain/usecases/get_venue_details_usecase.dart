import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/venue_entity.dart';
import '../repositories/venues_repository.dart';

class GetVenueDetailsUseCase {
  final VenuesRepository repository;

  GetVenueDetailsUseCase(this.repository);

  Future<Either<Failure, VenueEntity>> call(String id, {bool forceRefresh = false}) async {
    return await repository.getVenueDetails(id, forceRefresh: forceRefresh);
  }
}



