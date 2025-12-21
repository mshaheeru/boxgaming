import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../../../bookings/data/models/booking_model.dart';

abstract class OwnerRemoteDataSource {
  Future<DashboardModel> getTodayBookings();
  
  Future<void> markBookingStarted(String bookingId);
  
  Future<void> markBookingCompleted(String bookingId);
}

class OwnerRemoteDataSourceImpl implements OwnerRemoteDataSource {
  final ApiClient apiClient;

  OwnerRemoteDataSourceImpl(this.apiClient);

  @override
  Future<DashboardModel> getTodayBookings() async {
    try {
      // For now, use bookings endpoint - can be enhanced with dedicated endpoint
      final response = await apiClient.dio.get(ApiConstants.myBookings);
      final bookings = response.data as List<dynamic>? ?? [];
      
      // Calculate dashboard stats
      final today = DateTime.now();
      final todayBookings = bookings
          .whereType<Map<String, dynamic>>()
          .where((b) {
            try {
              final bookingDateStr = b['booking_date'] as String? ?? 
                                     b['bookingDate'] as String?;
              if (bookingDateStr == null) return false;
              final bookingDate = DateTime.tryParse(bookingDateStr);
              if (bookingDate == null) return false;
              return bookingDate.year == today.year &&
                  bookingDate.month == today.month &&
                  bookingDate.day == today.day;
            } catch (e) {
              return false;
            }
          })
          .toList();

      final todayRevenue = todayBookings.fold<double>(
        0.0,
        (sum, b) => sum + ((b['price'] as num?) ?? 0).toDouble(),
      );

      return DashboardModel(
        todayBookings: todayBookings
            .map((b) {
              try {
                return BookingModel.fromJson(b);
              } catch (e) {
                print('Error parsing booking in dashboard: $e');
                return null;
              }
            })
            .whereType<BookingModel>()
            .map((b) => b.toEntity())
            .toList(),
        todayRevenue: todayRevenue,
        totalBookings: bookings.length,
        totalRevenue: bookings
            .whereType<Map<String, dynamic>>()
            .fold<double>(
              0.0,
              (sum, b) => sum + ((b['price'] as num?) ?? 0).toDouble(),
            ),
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch dashboard data',
      );
    }
  }

  @override
  Future<void> markBookingStarted(String bookingId) async {
    try {
      await apiClient.dio.post(ApiConstants.startBooking(bookingId));
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to mark booking as started',
      );
    }
  }

  @override
  Future<void> markBookingCompleted(String bookingId) async {
    try {
      await apiClient.dio.post(ApiConstants.completeBooking(bookingId));
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to mark booking as completed',
      );
    }
  }
}

