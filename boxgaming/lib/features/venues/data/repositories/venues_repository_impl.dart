import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/cache/cache_helper.dart';
import '../../domain/entities/venue_entity.dart';
import '../../domain/entities/ground_entity.dart';
import '../../domain/repositories/venues_repository.dart';
import '../datasources/venues_remote_datasource.dart';
import '../models/venue_model.dart';
import '../models/ground_model.dart';

class VenuesRepositoryImpl implements VenuesRepository {
  final VenuesRemoteDataSource remoteDataSource;

  // Cache TTLs
  static const Duration _freshCacheTTL = Duration(minutes: 5);
  static const Duration _staleCacheTTL = Duration(minutes: 30);

  VenuesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VenueEntity>>> getVenues({
    String? search,
    String? city,
    SportType? sportType,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    // Build cache key (include search in cache key)
    final cacheKey = _buildCacheKey(search, city, sportType, lat, lng, page, limit);

    // Try to get from cache first (unless force refresh)
    if (!forceRefresh) {
      final cached = await CacheHelper.get<List<VenueModel>>(
        key: cacheKey,
        fromJson: (json) => (json['venues'] as List)
            .map((v) => VenueModel.fromJson(v as Map<String, dynamic>))
            .toList(),
        maxAge: _freshCacheTTL,
        staleAge: _staleCacheTTL,
      );

      if (cached != null) {
        // If cache is stale, refresh in background
        if (!CacheHelper.isValid(cacheKey, _freshCacheTTL)) {
          _refreshInBackground(search, city, sportType, lat, lng, page, limit, cacheKey);
        }
        return Right(cached.map((v) => v.toEntity()).toList());
      }
    }

      // Fetch fresh data
    try {
      final venues = await remoteDataSource.getVenues(
        search: search,
        city: city,
        sportType: sportType,
        lat: lat,
        lng: lng,
        page: page,
        limit: limit,
      );

      // Cache the result
      await CacheHelper.set<List<VenueModel>>(
        key: cacheKey,
        data: venues,
        toJson: (venues) => {'venues': venues.map((v) => v.toJson()).toList()},
      );

      return Right(venues.map((v) => v.toEntity()).toList());
    } on ServerException catch (e) {
      // On error, try to return stale cache if available
      final staleCache = await CacheHelper.get<List<VenueModel>>(
        key: cacheKey,
        fromJson: (json) => (json['venues'] as List)
            .map((v) => VenueModel.fromJson(v as Map<String, dynamic>))
            .toList(),
        staleAge: _staleCacheTTL,
      );
      if (staleCache != null) {
        return Right(staleCache.map((v) => v.toEntity()).toList());
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  /// Refresh cache in background (fire and forget)
  void _refreshInBackground(
    String? search,
    String? city,
    SportType? sportType,
    double? lat,
    double? lng,
    int page,
    int limit,
    String cacheKey,
  ) {
    remoteDataSource
        .getVenues(
          search: search,
          city: city,
          sportType: sportType,
          lat: lat,
          lng: lng,
          page: page,
          limit: limit,
        )
        .then((venues) async {
          await CacheHelper.set<List<VenueModel>>(
            key: cacheKey,
            data: venues,
            toJson: (venues) => {'venues': venues.map((v) => v.toJson()).toList()},
          );
        })
        .catchError((_) {
          // Silently fail - we already returned stale data
        });
  }

  String _buildCacheKey(
    String? search,
    String? city,
    SportType? sportType,
    double? lat,
    double? lng,
    int page,
    int limit,
  ) {
    return 'venues_${search ?? ''}_${city ?? ''}_${sportType?.name ?? ''}_${lat ?? ''}_${lng ?? ''}_$page\_$limit';
  }

  @override
  Future<Either<Failure, VenueEntity>> getVenueDetails(String id, {bool forceRefresh = false}) async {
    final cacheKey = 'venue_details_$id';

    // Try cache first
    if (!forceRefresh) {
      final cached = await CacheHelper.get<VenueModel>(
        key: cacheKey,
        fromJson: (json) => VenueModel.fromJson(json),
        maxAge: _freshCacheTTL,
        staleAge: _staleCacheTTL,
      );

      if (cached != null) {
        if (!CacheHelper.isValid(cacheKey, _freshCacheTTL)) {
          _refreshVenueDetailsInBackground(id, cacheKey);
        }
        return Right(cached.toEntity());
      }
    }

    try {
      final venue = await remoteDataSource.getVenueDetails(id);
      await CacheHelper.set<VenueModel>(
        key: cacheKey,
        data: venue,
        toJson: (v) => v.toJson(),
      );
      return Right(venue.toEntity());
    } on ServerException catch (e) {
      final staleCache = await CacheHelper.get<VenueModel>(
        key: cacheKey,
        fromJson: (json) => VenueModel.fromJson(json),
        staleAge: _staleCacheTTL,
      );
      if (staleCache != null) {
        return Right(staleCache.toEntity());
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  void _refreshVenueDetailsInBackground(String id, String cacheKey) {
    remoteDataSource.getVenueDetails(id).then((venue) async {
      await CacheHelper.set<VenueModel>(
        key: cacheKey,
        data: venue,
        toJson: (v) => v.toJson(),
      );
    }).catchError((_) {});
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

