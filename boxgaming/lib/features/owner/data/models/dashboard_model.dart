import '../../../bookings/data/models/booking_model.dart';
import '../../domain/entities/dashboard_entity.dart';

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required super.todayBookings,
    required super.todayRevenue,
    required super.totalBookings,
    required super.totalRevenue,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final bookingsJson = json['bookings'] as List<dynamic>?;
    final bookings = bookingsJson != null
        ? bookingsJson
            .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
            .toList()
        : <BookingModel>[];

    return DashboardModel(
      todayBookings: bookings.map((b) => b.toEntity()).toList(),
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      totalBookings: json['totalBookings'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DashboardEntity toEntity() {
    return DashboardEntity(
      todayBookings: todayBookings,
      todayRevenue: todayRevenue,
      totalBookings: totalBookings,
      totalRevenue: totalRevenue,
    );
  }
}

