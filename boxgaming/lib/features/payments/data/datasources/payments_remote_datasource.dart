import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/payment_model.dart';
import '../../domain/entities/payment_entity.dart';

abstract class PaymentsRemoteDataSource {
  Future<PaymentModel> initiatePayment(
    String bookingId,
    PaymentGateway gateway,
  );
}

class PaymentsRemoteDataSourceImpl implements PaymentsRemoteDataSource {
  final ApiClient apiClient;

  PaymentsRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaymentModel> initiatePayment(
    String bookingId,
    PaymentGateway gateway,
  ) async {
    try {
      final response = await apiClient.dio.post(
        ApiConstants.initiatePayment(bookingId),
        data: {'gateway': gateway.name},
      );
      try {
        return PaymentModel.fromJson(response.data as Map<String, dynamic>);
      } catch (e, stackTrace) {
        print('Error parsing payment response: $e');
        print('Stack trace: $stackTrace');
        print('Response data: ${response.data}');
        rethrow;
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Failed to initiate payment',
      );
    }
  }
}


