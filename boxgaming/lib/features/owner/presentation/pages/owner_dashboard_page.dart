import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/owner_bloc.dart';
import '../bloc/owner_event.dart';
import '../bloc/owner_state.dart';
import '../bloc/venue_management_bloc.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/extensions/bloc_extensions.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../domain/entities/dashboard_entity.dart';
import 'venue_management_page.dart';
import 'owner_bookings_page.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Always create a new instance to avoid using a closed Bloc from previous session
    // This prevents "Cannot add new events after calling close" errors after logout/login
    return BlocProvider(
      create: (context) => di.sl<OwnerBloc>(),
      child: _OwnerDashboardContent(),
    );
  }
}

class _OwnerDashboardContent extends StatefulWidget {
  const _OwnerDashboardContent();

  @override
  State<_OwnerDashboardContent> createState() => _OwnerDashboardContentState();
}

class _OwnerDashboardContentState extends State<_OwnerDashboardContent> {
  @override
  void initState() {
    super.initState();
    // Load bookings after the widget is fully mounted and BlocProvider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.safeReadBlocAdd<OwnerBloc, LoadTodayBookingsEvent>(
          LoadTodayBookingsEvent(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
      return DefaultTabController(
      length: 2,
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
              Tab(icon: Icon(Icons.book), text: 'Bookings'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: TabBarView(
          children: [
            _DashboardTab(),
            const OwnerBookingsPage(),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> with AutomaticKeepAliveClientMixin {
  DashboardEntity? _cachedDashboard;
  bool _hasLoadedOnce = false;

  @override
  bool get wantKeepAlive => true; // Keep the tab alive to preserve state

  @override
  void initState() {
    super.initState();
    // Load dashboard when tab is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoadedOnce) {
        _loadDashboard();
      }
    });
  }

  void _loadDashboard() {
    if (!mounted) return;
    final bloc = context.read<OwnerBloc>();
    if (!bloc.isClosed) {
      context.safeReadBlocAdd<OwnerBloc, LoadTodayBookingsEvent>(
        LoadTodayBookingsEvent(),
      );
      _hasLoadedOnce = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocConsumer<OwnerBloc, OwnerState>(
      listenWhen: (previous, current) {
        // Only listen to states relevant to dashboard
        return current is DashboardLoaded || 
               current is BookingStatusUpdated ||
               (current is OwnerError && _cachedDashboard == null);
      },
      listener: (context, state) {
        // Cache the dashboard when loaded
        if (state is DashboardLoaded) {
          _cachedDashboard = state.dashboard;
          _hasLoadedOnce = true;
        }
        // Reload dashboard when booking status is updated
        if (state is BookingStatusUpdated) {
          if (!context.mounted) return;
          context.safeReadBlocAdd<OwnerBloc, LoadTodayBookingsEvent>(
            LoadTodayBookingsEvent(),
          );
        }
      },
      buildWhen: (previous, current) {
        // If we have cached dashboard, always rebuild to show it
        if (_cachedDashboard != null) {
          return true;
        }
        // If state is AllBookingsLoaded and we don't have cached data, don't rebuild
        // (this is from the Bookings tab, not relevant to Dashboard)
        if (current is AllBookingsLoaded && _cachedDashboard == null) {
          return false;
        }
        // Rebuild for dashboard-relevant states
        return current is DashboardLoaded || 
               current is OwnerLoading || 
               current is OwnerError ||
               current is OwnerInitial;
      },
      builder: (context, state) {
        // Priority 1: Use DashboardLoaded state if available
        DashboardEntity? displayDashboard;
        if (state is DashboardLoaded) {
          displayDashboard = state.dashboard;
          _cachedDashboard = state.dashboard;
          _hasLoadedOnce = true;
        } 
        // Priority 2: Use cached dashboard if available (even if state is AllBookingsLoaded or OwnerLoading)
        else if (_cachedDashboard != null) {
          displayDashboard = _cachedDashboard;
        }

        // If we have dashboard data, show it immediately
        if (displayDashboard != null) {
          return RefreshIndicator(
            onRefresh: () async {
              if (!context.mounted) return;
              context.safeReadBlocAdd<OwnerBloc, LoadTodayBookingsEvent>(
                LoadTodayBookingsEvent(),
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsCards(dashboard: displayDashboard),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Today\'s Bookings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh dashboard',
                        onPressed: () {
                          if (!context.mounted) return;
                          context.safeReadBlocAdd<OwnerBloc, LoadTodayBookingsEvent>(
                            LoadTodayBookingsEvent(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (displayDashboard.todayBookings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No bookings for today'),
                      ),
                    )
                  else
                    ...displayDashboard.todayBookings.map(
                      (booking) => _BookingCard(booking: booking),
                    ),
                ],
              ),
            ),
          );
        }

        // No cached data - show loading or error
        if (state is OwnerLoading) {
          // If we haven't loaded yet, trigger load
          if (!_hasLoadedOnce && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadDashboard();
            });
          }
          return const LoadingWidget(message: 'Loading dashboard...');
        }

        if (state is OwnerError) {
          return ErrorDisplayWidget(
            message: state.message,
            onRetry: () {
              if (!context.mounted) return;
              _loadDashboard();
            },
          );
        }

        // Initial state or other states - show loading and trigger load if needed
        if (!_hasLoadedOnce && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadDashboard();
          });
        }
        return const LoadingWidget(message: 'Loading dashboard...');
      },
    );
  }
}

class _StatsCards extends StatelessWidget {
  final DashboardEntity dashboard;

  const _StatsCards({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First row: Total Revenue and Current Month Revenue
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Revenue',
                value: 'Rs. ${dashboard.totalRevenue.toStringAsFixed(0)}',
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Current Month Revenue',
                value: 'Rs. ${dashboard.currentMonthRevenue.toStringAsFixed(0)}',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row: Today's Revenue and Total Bookings this month
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Today\'s Revenue',
                value: 'Rs. ${dashboard.todayRevenue.toStringAsFixed(0)}',
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Total Bookings this month',
                value: '${dashboard.currentMonthBookings}',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Third row: Today's Bookings and Bookings In Progress
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Today\'s Bookings',
                value: '${dashboard.todayBookings.length}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Bookings In Progress',
                value: '${dashboard.bookingsInProgress}',
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
                        if (!context.mounted) return;
                        context.safeReadBlocAdd<OwnerBloc, MarkBookingStartedEvent>(
                          MarkBookingStartedEvent(booking.id),
                        );
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
                        if (!context.mounted) return;
                        context.safeReadBlocAdd<OwnerBloc, MarkBookingCompletedEvent>(
                          MarkBookingCompletedEvent(booking.id),
                        );
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
