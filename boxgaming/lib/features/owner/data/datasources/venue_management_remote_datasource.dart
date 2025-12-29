import 'dart:io';
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
  Future<String> uploadVenuePhoto(String venueId, File photo);
  Future<List<Map<String, dynamic>>> createOperatingHours(
    String venueId,
    List<Map<String, dynamic>> operatingHours,
  );
  Future<List<Map<String, dynamic>>> getVenueGrounds(String venueId);
  Future<Map<String, dynamic>> createGround(String venueId, Map<String, dynamic> groundData);
  Future<Map<String, dynamic>> updateGround(String venueId, String groundId, Map<String, dynamic> groundData);
  Future<void> deleteGround(String venueId, String groundId);
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

  @override
  Future<String> uploadVenuePhoto(String venueId, File photo) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.path),
      });

      final response = await apiClient.dio.post(
        ApiConstants.uploadVenuePhoto(venueId),
        data: formData,
      );

      final data = response.data as Map<String, dynamic>;
      return data['photoUrl'] as String;
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to upload photo',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> createOperatingHours(
    String venueId,
    List<Map<String, dynamic>> operatingHours,
  ) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.createOperatingHours(venueId),
        data: {
          'operating_hours': operatingHours,
        },
      );

      final data = response.data as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to create operating hours',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getVenueGrounds(String venueId) async {
    try {
      // Get all grounds including inactive ones for editing
      final response = await apiClient.dio.get(
        ApiConstants.venueGrounds(venueId),
        queryParameters: {'includeInactive': 'true'},
      );
      final data = response.data as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch grounds',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> createGround(String venueId, Map<String, dynamic> groundData) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.venueGrounds(venueId),
        data: groundData,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to create ground',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> updateGround(String venueId, String groundId, Map<String, dynamic> groundData) async {
    try {
      final response = await apiClient.dio.put(
        ApiConstants.updateGround(venueId, groundId),
        data: groundData,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to update ground',
      );
    }
  }

  @override
  Future<void> deleteGround(String venueId, String groundId) async {
    try {
      await apiClient.dio.delete(ApiConstants.deleteGround(venueId, groundId));
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to delete ground',
      );
    }
  }
}

