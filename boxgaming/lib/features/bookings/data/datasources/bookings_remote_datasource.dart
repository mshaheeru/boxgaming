import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/slot_model.dart';
import '../models/operating_hours_model.dart';
import '../models/day_slots_model.dart';

abstract class BookingsRemoteDataSource {
  Future<List<SlotModel>> getAvailableSlots(
    String groundId,
    DateTime date,
    int duration,
  );
  
  Future<List<OperatingHoursModel>> getOperatingHours(
    String venueId,
    String groundId,
  );
  
  Future<Map<String, DaySlotsModel>> getSlotsForDateRange(
    String groundId,
    DateTime startDate,
    DateTime endDate,
    int duration,
  );
  
  Future<BookingModel> createBooking({
    required String groundId,
    required DateTime bookingDate,
    required String startTime,
    required int durationHours,
    required String paymentMethod,
  });
  
  Future<List<BookingModel>> getMyBookings(String type);
  
  Future<BookingModel> getBookingDetails(String bookingId);
  
  Future<void> cancelBooking(String bookingId);
}

class BookingsRemoteDataSourceImpl implements BookingsRemoteDataSource {
  final ApiClient apiClient;

  BookingsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<SlotModel>> getAvailableSlots(
    String groundId,
    DateTime date,
    int duration,
  ) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.availableSlots(groundId),
        queryParameters: {
          'date': DateFormatters.formatDate(date),
          'duration': duration.toString(),
        },
      );
      final data = response.data as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            try {
              return SlotModel.fromJson(json);
            } catch (e) {
              print('Error parsing slot: $e');
              print('JSON: $json');
              rethrow;
            }
          })
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch available slots',
      );
    }
  }

  @override
  Future<List<OperatingHoursModel>> getOperatingHours(
    String venueId,
    String groundId,
  ) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.getGroundOperatingHours(venueId, groundId),
      );
      final data = response.data as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            try {
              return OperatingHoursModel.fromJson(json);
            } catch (e) {
              print('Error parsing operating hours: $e');
              print('JSON: $json');
              rethrow;
            }
          })
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch operating hours',
      );
    }
  }

  @override
  Future<Map<String, DaySlotsModel>> getSlotsForDateRange(
    String groundId,
    DateTime startDate,
    DateTime endDate,
    int duration,
  ) async {
    try {
      // Call existing endpoint for each date in the range
      final Map<String, DaySlotsModel> slotsByDate = {};
      
      DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      
      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
        try {
          final slots = await getAvailableSlots(groundId, currentDate, duration);
          // DateTime.weekday returns 1-7 (Monday=1, Sunday=7)
          // Database uses 0-6 (Sunday=0, Saturday=6)
          // Convert: Sunday (7) -> 0, Monday (1) -> 1, ..., Saturday (6) -> 6
          final weekday = currentDate.weekday; // 1-7
          final dayOfWeek = weekday == 7 ? 0 : weekday; // Convert to 0-6
          
          slotsByDate[DateFormatters.formatDate(currentDate)] = DaySlotsModel(
            date: currentDate,
            dayOfWeek: dayOfWeek,
            slots: slots.map((s) => s.toEntity()).toList(),
          );
        } catch (e) {
          // If a date fails, continue with other dates
          print('Error fetching slots for ${DateFormatters.formatDate(currentDate)}: $e');
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      return slotsByDate;
    } catch (e) {
      throw ServerException('Failed to fetch slots for date range: $e');
    }
  }

  @override
  Future<BookingModel> createBooking({
    required String groundId,
    required DateTime bookingDate,
    required String startTime,
    required int durationHours,
    required String paymentMethod,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.bookings,
        data: {
          'groundId': groundId,
          'bookingDate': DateFormatters.formatDate(bookingDate),
          'startTime': startTime,
          'durationHours': durationHours,
          'paymentMethod': paymentMethod,
        },
      );
      try {
        return BookingModel.fromJson(response.data as Map<String, dynamic>);
      } catch (e, stackTrace) {
        print('Error parsing booking response: $e');
        print('Stack trace: $stackTrace');
        print('Response data: ${response.data}');
        rethrow;
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to create booking',
      );
    }
  }

  @override
  Future<List<BookingModel>> getMyBookings(String type) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.myBookings,
        queryParameters: {'type': type},
      );
      final data = response.data as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) {
            try {
              return BookingModel.fromJson(json);
            } catch (e) {
              print('Error parsing booking: $e');
              print('JSON: $json');
              rethrow;
            }
          })
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch bookings',
      );
    }
  }

  @override
  Future<BookingModel> getBookingDetails(String bookingId) async {
    try {
      final response = await apiClient.dio.get(
        ApiConstants.bookingDetails(bookingId),
      );
      try {
        return BookingModel.fromJson(response.data as Map<String, dynamic>);
      } catch (e, stackTrace) {
        print('Error parsing booking details: $e');
        print('Stack trace: $stackTrace');
        print('Response data: ${response.data}');
        rethrow;
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to fetch booking details',
      );
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    try {
      await apiClient.dio.post(ApiConstants.cancelBooking(bookingId));
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to cancel booking',
      );
    }
  }
}


