import 'package:equatable/equatable.dart';

enum BookingStatus {
  confirmed,
  started,
  completed,
  cancelled,
  noShow,
}

enum PaymentStatus {
  paid,
  refunded,
}

enum PaymentGateway {
  jazzcash,
  easypaisa,
  card,
  payfast,
}

class BookingEntity extends Equatable {
  final String id;
  final String bookingCode;
  final String customerId;
  final String groundId;
  final String venueId;
  final DateTime bookingDate;
  final String startTime;
  final int durationHours;
  final double price;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final PaymentGateway? paymentMethod;
  final String? paymentId;
  final String? qrCode;
  final DateTime createdAt;
  
  // Related data (optional, populated when needed)
  final String? venueName;
  final String? groundName;
  final String? customerName;
  final String? customerPhone;

  const BookingEntity({
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

  @override
  List<Object?> get props => [
        id,
        bookingCode,
        customerId,
        groundId,
        venueId,
        bookingDate,
        startTime,
        durationHours,
        price,
        status,
        paymentStatus,
        paymentMethod,
        paymentId,
        qrCode,
        createdAt,
        venueName,
        groundName,
        customerName,
        customerPhone,
      ];
}



