import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/venue_entity.dart';
import '../../domain/entities/ground_entity.dart';
import '../../domain/repositories/venues_repository.dart';
import '../datasources/venues_remote_datasource.dart';

class VenuesRepositoryImpl implements VenuesRepository {
  final VenuesRemoteDataSource remoteDataSource;

  VenuesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VenueEntity>>> getVenues({
    String? city,
    SportType? sportType,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final venues = await remoteDataSource.getVenues(
        city: city,
        sportType: sportType,
        lat: lat,
        lng: lng,
        page: page,
        limit: limit,
      );
      return Right(venues.map((v) => v.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, VenueEntity>> getVenueDetails(String id) async {
    try {
      final venue = await remoteDataSource.getVenueDetails(id);
      return Right(venue.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<GroundEntity>>> getVenueGrounds(String venueId) async {
    try {
      final grounds = await remoteDataSource.getVenueGrounds(venueId);
      return Right(grounds.map((g) => g.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

