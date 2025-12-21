import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/venue_model.dart';
import '../models/ground_model.dart';
import '../../domain/entities/venue_entity.dart';

abstract class VenuesRemoteDataSource {
  Future<List<VenueModel>> getVenues({
    String? city,
    SportType? sportType,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
  });
  
  Future<VenueModel> getVenueDetails(String id);
  
  Future<List<GroundModel>> getVenueGrounds(String venueId);
}

class VenuesRemoteDataSourceImpl implements VenuesRemoteDataSource {
  final ApiClient apiClient;

  VenuesRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<VenueModel>> getVenues({
    String? city,
    SportType? sportType,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (city != null) queryParams['city'] = city;
      if (sportType != null) {
        queryParams['sportType'] = sportType.name;
      }
      if (lat != null) queryParams['lat'] = lat;
      if (lng != null) queryParams['lng'] = lng;

      final response = await apiClient.dio.get(
        ApiConstants.venues,
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            try {
              return VenueModel.fromJson(json);
            } catch (e, stackTrace) {
              print('Error parsing venue: $e');
              print('Stack trace: $stackTrace');
              print('JSON data: $json');
              rethrow;
            }
          })
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch venues',
      );
    }
  }

  @override
  Future<VenueModel> getVenueDetails(String id) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.venueDetails(id),
      );
      try {
        return VenueModel.fromJson(response.data as Map<String, dynamic>);
      } catch (e, stackTrace) {
        print('Error parsing venue details: $e');
        print('Stack trace: $stackTrace');
        print('Response data: ${response.data}');
        rethrow;
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch venue details',
      );
    }
  }

  @override
  Future<List<GroundModel>> getVenueGrounds(String venueId) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.venueGrounds(venueId),
      );
      final data = response.data as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            try {
              return GroundModel.fromJson(json);
            } catch (e) {
              print('Error parsing ground: $e');
              print('JSON: $json');
              rethrow;
            }
          })
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch venue grounds',
      );
    }
  }
}


