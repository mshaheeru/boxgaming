import 'package:equatable/equatable.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

class DashboardEntity extends Equatable {
  final List<BookingEntity> todayBookings;
  final double todayRevenue;
  final int totalBookings;
  final double totalRevenue;
  final double currentMonthRevenue;
  final int currentMonthBookings;
  final int bookingsInProgress;

  const DashboardEntity({
    required this.todayBookings,
    required this.todayRevenue,
    required this.totalBookings,
    required this.totalRevenue,
    required this.currentMonthRevenue,
    required this.currentMonthBookings,
    required this.bookingsInProgress,
  });

  @override
  List<Object?> get props => [
        todayBookings,
        todayRevenue,
        totalBookings,
        totalRevenue,
        currentMonthRevenue,
        currentMonthBookings,
        bookingsInProgress,
      ];
}

