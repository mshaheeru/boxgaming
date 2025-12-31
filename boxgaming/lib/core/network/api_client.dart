import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'interceptors.dart';

class ApiClient {
  late Dio _dio;
  final SecureStorage _secureStorage;

  ApiClient(this._secureStorage) {
    final baseUrl = ApiConstants.baseUrl;
    // Log the base URL for debugging (remove in production)
    print('🔗 API Base URL: $baseUrl');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Enable request cancellation
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_secureStorage),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}

