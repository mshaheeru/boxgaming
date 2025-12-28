import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      print('✅ Using API_BASE_URL from .env: $envUrl');
      return envUrl;
    }
    // Fallback
    print('⚠️ API_BASE_URL not found in .env, using fallback: http://localhost:3000/api/v1');
    print('⚠️ Please create .env file with: API_BASE_URL=http://YOUR_IP:3001/api/v1');
    return 'http://localhost:3000/api/v1';
  }
  
  // Auth endpoints
  static const String signUp = '/auth/signup';
  static const String signIn = '/auth/signin';
  static const String changePassword = '/auth/change-password';
  
  // Venues endpoints
  static const String venues = '/venues';
  static String venueDetails(String id) => '/venues/$id';
  static String venueGrounds(String venueId) => '/venues/$venueId/grounds';
  static const String myVenues = '/venues/my-venues';
  static String activateVenue(String id) => '/venues/$id/activate';
  static String deactivateVenue(String id) => '/venues/$id/deactivate';
  
  // Bookings endpoints
  static String availableSlots(String groundId) => '/bookings/grounds/$groundId/slots';
  static const String bookings = '/bookings';
  static String myBookings = '/bookings/my-bookings';
  static String bookingDetails(String id) => '/bookings/$id';
  static String cancelBooking(String id) => '/bookings/$id/cancel';
  static String startBooking(String id) => '/bookings/$id/start';
  static String completeBooking(String id) => '/bookings/$id/complete';
  
  // Payments endpoints
  static String initiatePayment(String bookingId) => '/payments/initiate/$bookingId';
  
  // Users endpoints
  static const String currentUser = '/users/me';
  
  // Admin endpoints
  static const String createOwner = '/tenants';
  static const String getAllTenants = '/tenants';
  static const String getAllBookings = '/bookings';
  static const String getAllVenues = '/venues';
  static String resetOwnerPassword(String tenantId) => '/tenants/$tenantId/owner/reset-password';
}

