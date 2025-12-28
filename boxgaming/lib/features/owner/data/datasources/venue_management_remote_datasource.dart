import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../venues/data/models/venue_model.dart';
import '../../../venues/dto/create_venue_dto.dart';
import '../../../venues/dto/update_venue_dto.dart';

abstract class VenueManagementRemoteDataSource {
  Future<List<VenueModel>> getMyVenues();
  Future<VenueModel> createVenue(CreateVenueDto dto);
  Future<VenueModel> updateVenue(String id, UpdateVenueDto dto);
  Future<void> activateVenue(String id);
  Future<void> deactivateVenue(String id);
}

class VenueManagementRemoteDataSourceImpl
    implements VenueManagementRemoteDataSource {
  final ApiClient apiClient;

  VenueManagementRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<VenueModel>> getMyVenues() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.myVenues);
      final data = response.data as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => VenueModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch venues',
      );
    }
  }

  @override
  Future<VenueModel> createVenue(CreateVenueDto dto) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.venues,
        data: dto.toJson(),
      );
      return VenueModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to create venue',
      );
    }
  }

  @override
  Future<VenueModel> updateVenue(String id, UpdateVenueDto dto) async {
    try {
      final response = await apiClient.dio.put(
        ApiConstants.venueDetails(id),
        data: dto.toJson(),
      );
      return VenueModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to update venue',
      );
    }
  }

  @override
  Future<void> activateVenue(String id) async {
    try {
      await apiClient.dio.put(ApiConstants.activateVenue(id));
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to activate venue',
      );
    }
  }

  @override
  Future<void> deactivateVenue(String id) async {
    try {
      await apiClient.dio.put(ApiConstants.deactivateVenue(id));
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to deactivate venue',
      );
    }
  }
}

