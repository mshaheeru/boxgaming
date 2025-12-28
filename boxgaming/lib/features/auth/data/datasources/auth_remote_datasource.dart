import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/auth_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> signUp(String email, String password, String? name);
  Future<AuthResponseModel> signIn(String email, String password);
  Future<UserModel> getCurrentUser();
  Future<void> changePassword(String currentPassword, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<AuthResponseModel> signUp(String email, String password, String? name) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.signUp,
        data: {
          'email': email,
          'password': password,
          if (name != null && name.isNotEmpty) 'name': name,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.data is! Map<String, dynamic>) {
        throw ServerException('Invalid response format from server');
      }
      
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      String errorMessage = 'Failed to sign up';
      
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
      throw ServerException('Failed to sign up: ${e.toString()}');
    }
  }

  @override
  Future<AuthResponseModel> signIn(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.signIn,
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.data is! Map<String, dynamic>) {
        throw ServerException('Invalid response format from server');
      }
      
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      String errorMessage = 'Failed to sign in';
      
      if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 
                     e.response?.data['error'] ?? 
                     'Invalid email or password';
      } else {
        errorMessage = e.message ?? 'Network error occurred';
      }
      
      throw ServerException(errorMessage);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Failed to sign in: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.currentUser,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      String errorMessage = 'Failed to get user';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Unauthorized';
      } else if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Cannot connect to server';
      } else if (e.response != null) {
        errorMessage = e.response?.data['message'] ?? 
                      e.response?.data['error'] ?? 
                      'Server error: ${e.response?.statusCode}';
      } else {
        errorMessage = e.message ?? 'Network error occurred';
      }
      
      throw ServerException(errorMessage);
    } catch (e) {
      throw ServerException('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      // Success - no data to return
      if (response.statusCode != 200) {
        throw ServerException('Failed to change password');
      }
    } on DioException catch (e) {
      String errorMessage = 'Failed to change password';
      
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
      throw ServerException('Failed to change password: ${e.toString()}');
    }
  }
}

