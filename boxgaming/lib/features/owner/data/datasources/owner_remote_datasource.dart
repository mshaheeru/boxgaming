import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../../../bookings/data/models/booking_model.dart';

abstract class OwnerRemoteDataSource {
  Future<DashboardModel> getTodayBookings();
  
  Future<List<BookingModel>> getAllBookings();
  
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
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final currentMonthStart = DateTime(now.year, now.month, 1);
      
      final bookingsList = bookings.whereType<Map<String, dynamic>>().toList();
      
      // Today's bookings
      final todayBookings = bookingsList.where((b) {
        try {
          final bookingDateStr = b['booking_date'] as String? ?? 
                                 b['bookingDate'] as String?;
          if (bookingDateStr == null) return false;
          final bookingDate = DateTime.tryParse(bookingDateStr);
          if (bookingDate == null) return false;
          final bookingDay = DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
          return bookingDay.isAtSameMomentAs(today);
        } catch (e) {
          return false;
        }
      }).toList();

      final todayRevenue = todayBookings.fold<double>(
        0.0,
        (sum, b) => sum + ((b['price'] as num?) ?? 0).toDouble(),
      );

      // Current month bookings and revenue
      final currentMonthBookingsList = bookingsList.where((b) {
        try {
          final bookingDateStr = b['booking_date'] as String? ?? 
                                 b['bookingDate'] as String?;
          if (bookingDateStr == null) return false;
          final bookingDate = DateTime.tryParse(bookingDateStr);
          if (bookingDate == null) return false;
          return bookingDate.year == now.year && bookingDate.month == now.month;
        } catch (e) {
          return false;
        }
      }).toList();

      final currentMonthRevenue = currentMonthBookingsList.fold<double>(
        0.0,
        (sum, b) => sum + ((b['price'] as num?) ?? 0).toDouble(),
      );

      final currentMonthBookings = currentMonthBookingsList.length;

      // Bookings in progress (confirmed or started status)
      final bookingsInProgress = bookingsList.where((b) {
        final status = b['status'] as String?;
        return status == 'confirmed' || status == 'started';
      }).length;

      // Total revenue (all time)
      final totalRevenue = bookingsList.fold<double>(
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
        totalBookings: bookingsList.length,
        totalRevenue: totalRevenue,
        currentMonthRevenue: currentMonthRevenue,
        currentMonthBookings: currentMonthBookings,
        bookingsInProgress: bookingsInProgress,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch dashboard data',
      );
    }
  }

  @override
  Future<List<BookingModel>> getAllBookings() async {
    try {
      // Use the my-bookings endpoint which for owners returns all their bookings
      final response = await apiClient.dio.get(ApiConstants.myBookings);
      final bookings = response.data as List<dynamic>? ?? [];
      
      return bookings
          .whereType<Map<String, dynamic>>()
          .map((b) {
            try {
              return BookingModel.fromJson(b);
            } catch (e) {
              print('Error parsing booking: $e');
              return null;
            }
          })
          .whereType<BookingModel>()
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch bookings',
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

