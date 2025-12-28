import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/owner_creation_response_model.dart';

abstract class AdminRemoteDataSource {
  Future<OwnerCreationResponseModel> createOwner({
    required String email,
    required String tenantName,
    String? name,
    String? temporaryPassword,
  });
  
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<Map<String, dynamic>>> getAllOwners();
  Future<Map<String, dynamic>> resetOwnerPassword(String tenantId);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient apiClient;

  AdminRemoteDataSourceImpl(this.apiClient);

  @override
  Future<OwnerCreationResponseModel> createOwner({
    required String email,
    required String tenantName,
    String? name,
    String? temporaryPassword,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.createOwner,
        data: {
          'email': email,
          'tenantName': tenantName,
          if (name != null && name.isNotEmpty) 'name': name,
          if (temporaryPassword != null && temporaryPassword.isNotEmpty)
            'temporaryPassword': temporaryPassword,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data is! Map<String, dynamic>) {
        print('❌ Invalid response format: ${response.data.runtimeType}');
        throw ServerException('Invalid response format from server');
      }

      final responseData = response.data as Map<String, dynamic>;
      print('📦 Backend response: ${responseData.keys}');
      print('📦 Owner data: ${responseData['owner']}');
      print('📦 Temp password: ${responseData['temporaryPassword']}');
      
      return OwnerCreationResponseModel.fromJson(responseData);
    } on DioException catch (e) {
      String errorMessage = 'Failed to create owner';

      if (e.response != null) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Server error: ${e.response?.statusCode}';
      } else {
        errorMessage = e.message ?? 'Network error occurred';
      }

      throw ServerException(errorMessage);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to create owner: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get all tenants (which includes owners)
      final tenantsResponse = await apiClient.dio.get(ApiConstants.getAllTenants);
      final tenants = tenantsResponse.data as List<dynamic>? ?? [];
      
      // Get all venues
      final venuesResponse = await apiClient.dio.get(ApiConstants.getAllVenues);
      final venues = venuesResponse.data is Map
          ? (venuesResponse.data['data'] as List<dynamic>? ?? [])
          : (venuesResponse.data as List<dynamic>? ?? []);
      
      // Get all bookings
      final bookingsResponse = await apiClient.dio.get(ApiConstants.getAllBookings);
      final bookings = bookingsResponse.data is Map
          ? (bookingsResponse.data['data'] as List<dynamic>? ?? [])
          : (bookingsResponse.data as List<dynamic>? ?? []);

      final activeVenues = venues.where((v) {
        final venue = v as Map<String, dynamic>;
        return venue['status'] == 'active';
      }).length;

      return {
        'totalTenants': tenants.length,
        'totalOwners': tenants.length, // Each tenant has one owner
        'activeVenues': activeVenues,
        'totalBookings': bookings.length,
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to load dashboard stats';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Server error: ${e.response?.statusCode}';
      } else {
        errorMessage = e.message ?? 'Network error occurred';
      }
      throw ServerException(errorMessage);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to load dashboard stats: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllOwners() async {
    try {
      final response = await apiClient.dio.get(ApiConstants.getAllTenants);
      final tenants = response.data as List<dynamic>? ?? [];
      
      // Transform tenants to owners list
      return tenants.map((tenant) {
        final t = tenant as Map<String, dynamic>;
        final owner = t['owner'] as Map<String, dynamic>? ?? {};
        return {
          'id': owner['id'] ?? '',
          'email': owner['email'] ?? '',
          'name': owner['name'] ?? '',
          'phone': owner['phone'] ?? '',
          'tenantName': t['name'] ?? '',
          'tenantId': t['id'] ?? '',
          'tenantStatus': t['status'] ?? 'active',
          'createdAt': owner['created_at'] ?? t['created_at'] ?? '',
          'requiresPasswordChange': owner['requires_password_change'] ?? false,
          'temporaryPassword': owner['temporary_password'] ?? null, // Include temporary password
        };
      }).toList();
    } on DioException catch (e) {
      String errorMessage = 'Failed to load owners';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Server error: ${e.response?.statusCode}';
      } else {
        errorMessage = e.message ?? 'Network error occurred';
      }
      throw ServerException(errorMessage);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to load owners: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> resetOwnerPassword(String tenantId) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.resetOwnerPassword(tenantId),
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data is! Map<String, dynamic>) {
        throw ServerException('Invalid response format from server');
      }

      final responseData = response.data as Map<String, dynamic>;
      // Get owner email from the tenant
      final tenantsResponse = await apiClient.dio.get(ApiConstants.getAllTenants);
      final tenants = tenantsResponse.data as List<dynamic>;
      String ownerEmail = '';
      try {
        final tenant = tenants.firstWhere(
          (t) => (t as Map<String, dynamic>)['id'] == tenantId,
        ) as Map<String, dynamic>?;
        if (tenant != null) {
          ownerEmail = tenant['owner']?['email'] ?? '';
        }
      } catch (e) {
        // Tenant not found, ownerEmail remains empty
      }

      return {
        'email': ownerEmail,
        'temporaryPassword': responseData['temporaryPassword'] ?? '',
      };
    } on DioException catch (e) {
      String errorMessage = 'Failed to reset password';
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Server error: ${e.response?.statusCode}';
      } else {
        errorMessage = e.message ?? 'Network error occurred';
      }
      throw ServerException(errorMessage);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to reset password: ${e.toString()}');
    }
  }
}

