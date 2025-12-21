import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/owner_bloc.dart';
import '../bloc/owner_event.dart';
import '../bloc/owner_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../domain/entities/dashboard_entity.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<OwnerBloc>()..add(LoadTodayBookingsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Owner Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () {
                context.push(RouteConstants.qrScanner);
              },
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: BlocBuilder<OwnerBloc, OwnerState>(
          builder: (context, state) {
            if (state is OwnerLoading) {
              return const LoadingWidget(message: 'Loading dashboard...');
            }

            if (state is OwnerError) {
              return ErrorDisplayWidget(
                message: state.message,
                onRetry: () {
                  context.read<OwnerBloc>().add(LoadTodayBookingsEvent());
                },
              );
            }

            if (state is DashboardLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<OwnerBloc>().add(LoadTodayBookingsEvent());
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatsCards(dashboard: state.dashboard),
                      const SizedBox(height: 24),
                      const Text(
                        'Today\'s Bookings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.dashboard.todayBookings.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No bookings for today'),
                          ),
                        )
                      else
                        ...state.dashboard.todayBookings.map(
                          (booking) => _BookingCard(booking: booking),
                        ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  final DashboardEntity dashboard;

  const _StatsCards({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.blue,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Today\'s Revenue',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${dashboard.todayRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            color: Colors.green,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Today\'s Bookings',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${dashboard.todayBookings.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingEntity booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.venueName ?? 'Venue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (booking.groundName != null)
                        Text(
                          booking.groundName!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text('${booking.startTime} (${booking.durationHours} hrs)'),
                const Spacer(),
                Text(
                  'Rs. ${booking.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final ownerBloc = context.read<OwnerBloc>();
                        ownerBloc.add(MarkBookingStartedEvent(booking.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking marked as started')),
                        );
                      },
                      child: const Text('Mark Started'),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == BookingStatus.started) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final ownerBloc = context.read<OwnerBloc>();
                        ownerBloc.add(MarkBookingCompletedEvent(booking.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking marked as completed')),
                        );
                      },
                      child: const Text('Mark Completed'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.confirmed:
        color = Colors.green;
        label = 'Confirmed';
        break;
      case BookingStatus.started:
        color = Colors.blue;
        label = 'Started';
        break;
      case BookingStatus.completed:
        color = Colors.grey;
        label = 'Completed';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = 'Cancelled';
        break;
      case BookingStatus.noShow:
        color = Colors.orange;
        label = 'No Show';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }
}
