import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/payment_entity.dart';

part 'payment_model.g.dart';

@JsonSerializable()
class PaymentModel {
  final String id;
  @JsonKey(name: 'bookingId', fromJson: _bookingIdFromJson)
  final String bookingId;
  final double amount;
  final String gateway;
  @JsonKey(name: 'paymentUrl', fromJson: _paymentUrlFromJson)
  final String? paymentUrl;
  @JsonKey(name: 'transactionId', fromJson: _transactionIdFromJson)
  final String? transactionId;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.gateway,
    this.paymentUrl,
    this.transactionId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModelFromJson(json);

  static String _bookingIdFromJson(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static String? _paymentUrlFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static String? _transactionIdFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static PaymentGateway _parseGateway(String gateway) {
    switch (gateway) {
      case 'jazzcash':
        return PaymentGateway.jazzcash;
      case 'easypaisa':
        return PaymentGateway.easypaisa;
      case 'card':
        return PaymentGateway.card;
      case 'payfast':
        return PaymentGateway.payfast;
      default:
        return PaymentGateway.jazzcash;
    }
  }

  Map<String, dynamic> toJson() => _$PaymentModelToJson(this);

  PaymentEntity toEntity() {
    return PaymentEntity(
      id: id,
      bookingId: bookingId,
      amount: amount,
      gateway: _parseGateway(gateway),
      paymentUrl: paymentUrl,
      transactionId: transactionId,
    );
  }
}

