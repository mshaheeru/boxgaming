class AppConstants {
  // App Info
  static const String appName = 'BoxGaming';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Timeouts (optimized for better UX)
  static const Duration connectionTimeout = Duration(seconds: 10); // Reduced from 30
  static const Duration receiveTimeout = Duration(seconds: 15); // Reduced from 30
  static const Duration sendTimeout = Duration(seconds: 10); // New: timeout for sending data
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // OTP
  static const int otpLength = 6;
  
  // Booking
  static const List<int> bookingDurations = [2, 3]; // hours
}



