import 'package:equatable/equatable.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

class DashboardEntity extends Equatable {
  final List<BookingEntity> todayBookings;
  final double todayRevenue;
  final int totalBookings;
  final double totalRevenue;

  const DashboardEntity({
    required this.todayBookings,
    required this.todayRevenue,
    required this.totalBookings,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [
        todayBookings,
        todayRevenue,
        totalBookings,
        totalRevenue,
      ];
}

