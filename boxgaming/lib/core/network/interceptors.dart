import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final fullUrl = '${options.baseUrl}${options.path}';
    _logger.d('Request: ${options.method} ${options.path}');
    _logger.d('Full URL: $fullUrl');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Don't log 401 errors as errors - they're expected when checking auth status
    if (err.response?.statusCode == 401 && err.requestOptions.path.contains('/users/me')) {
      _logger.d('Auth check: Not authenticated (401)');
    } else {
      _logger.e('Error: ${err.type} - ${err.message}');
      _logger.e('Error path: ${err.requestOptions.path}');
      _logger.e('Full URL: ${err.requestOptions.uri}');
      _logger.e('Base URL: ${err.requestOptions.baseUrl}');
      if (err.response != null) {
        _logger.e('Error response: ${err.response?.data}');
        _logger.e('Error status: ${err.response?.statusCode}');
      } else {
        _logger.e('No response received - Connection error');
        _logger.e('Error type: ${err.type}');
        if (err.type == DioExceptionType.connectionError) {
          _logger.e('Cannot reach server at: ${err.requestOptions.uri}');
        }
      }
    }
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 401 Unauthorized - this is expected when checking auth status without token
      // Don't log as error, just pass it through
      // The auth repository will handle it gracefully
    }
    handler.next(err);
  }
}

