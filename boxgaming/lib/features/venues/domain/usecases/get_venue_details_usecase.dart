import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/venue_entity.dart';
import '../repositories/venues_repository.dart';

class GetVenueDetailsUseCase {
  final VenuesRepository repository;

  GetVenueDetailsUseCase(this.repository);

  Future<Either<Failure, VenueEntity>> call(String id) async {
    return await repository.getVenueDetails(id);
  }
}


