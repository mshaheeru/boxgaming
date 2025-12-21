import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/booking_entity.dart';

part 'booking_model.g.dart';

@JsonSerializable()
class BookingModel {
  final String id;
  @JsonKey(name: 'bookingCode')
  final String bookingCode;
  @JsonKey(name: 'customerId')
  final String customerId;
  @JsonKey(name: 'groundId')
  final String groundId;
  @JsonKey(name: 'venueId')
  final String venueId;
  @JsonKey(name: 'bookingDate')
  final DateTime bookingDate;
  @JsonKey(name: 'startTime')
  final String startTime;
  @JsonKey(name: 'durationHours')
  final int durationHours;
  final double price;
  final String status;
  @JsonKey(name: 'paymentStatus')
  final String paymentStatus;
  @JsonKey(name: 'paymentMethod')
  final String? paymentMethod;
  @JsonKey(name: 'paymentId')
  final String? paymentId;
  @JsonKey(name: 'qrCode')
  final String? qrCode;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? venueName;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? groundName;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? customerName;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? customerPhone;

  BookingModel({
    required this.id,
    required this.bookingCode,
    required this.customerId,
    required this.groundId,
    required this.venueId,
    required this.bookingDate,
    required this.startTime,
    required this.durationHours,
    required this.price,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentId,
    this.qrCode,
    required this.createdAt,
    this.venueName,
    this.groundName,
    this.customerName,
    this.customerPhone,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Handle nested objects
    final ground = json['ground'] as Map<String, dynamic>?;
    final venue = ground?['venue'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;

    // Handle both snake_case (from backend) and camelCase field names
    final id = json['id'] as String? ?? '';
    final bookingCode = json['booking_code'] as String? ?? json['bookingCode'] as String? ?? '';
    final customerId = json['customer_id'] as String? ?? json['customerId'] as String? ?? '';
    final groundId = json['ground_id'] as String? ?? json['groundId'] as String? ?? '';
    final venueId = json['venue_id'] as String? ?? json['venueId'] as String? ?? '';
    final bookingDateStr = json['booking_date'] as String? ?? json['bookingDate'] as String?;
    final startTime = json['start_time'] as String? ?? json['startTime'] as String? ?? '';
    final durationHours = json['duration_hours'] as int? ?? json['durationHours'] as int? ?? 2;
    final price = ((json['price'] as num?) ?? 0).toDouble();
    final status = json['status'] as String? ?? 'confirmed';
    final paymentStatus = json['payment_status'] as String? ?? json['paymentStatus'] as String? ?? 'pending';
    final paymentMethod = json['payment_method'] as String? ?? json['paymentMethod'] as String?;
    final paymentId = json['payment_id'] as String? ?? json['paymentId'] as String?;
    final qrCode = json['qr_code'] as String? ?? json['qrCode'] as String?;
    final createdAtStr = json['created_at'] as String? ?? json['createdAt'] as String?;

    return BookingModel(
      id: id,
      bookingCode: bookingCode,
      customerId: customerId,
      groundId: groundId,
      venueId: venueId,
      bookingDate: bookingDateStr != null 
          ? DateTime.parse(bookingDateStr) 
          : DateTime.now(),
      startTime: startTime,
      durationHours: durationHours,
      price: price,
      status: status,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      paymentId: paymentId,
      qrCode: qrCode,
      createdAt: createdAtStr != null 
          ? DateTime.parse(createdAtStr) 
          : DateTime.now(),
      venueName: venue?['name'] as String?,
      groundName: ground?['name'] as String?,
      customerName: customer?['name'] as String?,
      customerPhone: customer?['phone'] as String?,
    );
  }

  static BookingStatus _parseStatus(String status) {
    switch (status) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'started':
        return BookingStatus.started;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'no_show':
        return BookingStatus.noShow;
      default:
        return BookingStatus.confirmed;
    }
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.paid;
    }
  }

  static PaymentGateway _parsePaymentGateway(String gateway) {
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

  Map<String, dynamic> toJson() => _$BookingModelToJson(this);

  BookingEntity toEntity() {
    return BookingEntity(
      id: id,
      bookingCode: bookingCode,
      customerId: customerId,
      groundId: groundId,
      venueId: venueId,
      bookingDate: bookingDate,
      startTime: startTime,
      durationHours: durationHours,
      price: price,
      status: _parseStatus(status),
      paymentStatus: _parsePaymentStatus(paymentStatus),
      paymentMethod: paymentMethod != null
          ? _parsePaymentGateway(paymentMethod!)
          : null,
      paymentId: paymentId,
      qrCode: qrCode,
      createdAt: createdAt,
      venueName: venueName,
      groundName: groundName,
      customerName: customerName,
      customerPhone: customerPhone,
    );
  }
}

