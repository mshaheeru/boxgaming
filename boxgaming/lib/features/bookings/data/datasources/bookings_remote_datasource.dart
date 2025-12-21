import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/network/api_client.dart';
import '../models/booking_model.dart';
import '../models/slot_model.dart';

abstract class BookingsRemoteDataSource {
  Future<List<SlotModel>> getAvailableSlots(
    String groundId,
    DateTime date,
    int duration,
  );
  
  Future<BookingModel> createBooking({
    required String groundId,
    required DateTime bookingDate,
    required String startTime,
    required int durationHours,
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
  Future<BookingModel> createBooking({
    required String groundId,
    required DateTime bookingDate,
    required String startTime,
    required int durationHours,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.bookings,
        data: {
          'groundId': groundId,
          'bookingDate': DateFormatters.formatDate(bookingDate),
          'startTime': startTime,
          'durationHours': durationHours,
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


