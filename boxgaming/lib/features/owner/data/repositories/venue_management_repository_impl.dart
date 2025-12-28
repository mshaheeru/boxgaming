import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/venue_management_repository.dart';
import '../datasources/venue_management_remote_datasource.dart';
import '../../../venues/domain/entities/venue_entity.dart';
import '../../../venues/dto/create_venue_dto.dart';
import '../../../venues/dto/update_venue_dto.dart';

class VenueManagementRepositoryImpl implements VenueManagementRepository {
  final VenueManagementRemoteDataSource remoteDataSource;

  VenueManagementRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VenueEntity>>> getMyVenues() async {
    try {
      final venues = await remoteDataSource.getMyVenues();
      return Right(venues.map((v) => v.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, VenueEntity>> createVenue(CreateVenueDto dto) async {
    try {
      final venue = await remoteDataSource.createVenue(dto);
      return Right(venue.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, VenueEntity>> updateVenue(
    String id,
    UpdateVenueDto dto,
  ) async {
    try {
      final venue = await remoteDataSource.updateVenue(id, dto);
      return Right(venue.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> activateVenue(String id) async {
    try {
      await remoteDataSource.activateVenue(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateVenue(String id) async {
    try {
      await remoteDataSource.deactivateVenue(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

