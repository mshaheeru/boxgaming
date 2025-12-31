import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/owner_bloc.dart';
import '../bloc/owner_event.dart';
import '../bloc/owner_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/extensions/bloc_extensions.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

class OwnerBookingsPage extends StatefulWidget {
  const OwnerBookingsPage({super.key});

  @override
  State<OwnerBookingsPage> createState() => _OwnerBookingsPageState();
}

class _OwnerBookingsPageState extends State<OwnerBookingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep the tab alive to preserve state

  String _selectedFilter = 'all'; // 'all', 'upcoming', 'past', 'today'
  bool _isLocked = false; // Lock state for booking card buttons

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.safeReadBlocAdd<OwnerBloc, LoadAllBookingsEvent>(
          LoadAllBookingsEvent(),
        );
      }
    });
  }

  List<BookingEntity> _filterBookings(List<BookingEntity> bookings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedFilter) {
      case 'today':
        return bookings.where((b) {
          final bookingDate = DateTime(
            b.bookingDate.year,
            b.bookingDate.month,
            b.bookingDate.day,
          );
          return bookingDate.isAtSameMomentAs(today);
        }).toList();
      case 'upcoming':
        return bookings.where((b) {
          final bookingDate = DateTime(
            b.bookingDate.year,
            b.bookingDate.month,
            b.bookingDate.day,
          );
          return bookingDate.isAfter(today) ||
              (bookingDate.isAtSameMomentAs(today) &&
                  _isTimeAfterNow(b.startTime));
        }).toList();
      case 'past':
        return bookings.where((b) {
          final bookingDate = DateTime(
            b.bookingDate.year,
            b.bookingDate.month,
            b.bookingDate.day,
          );
          return bookingDate.isBefore(today) ||
              (bookingDate.isAtSameMomentAs(today) &&
                  !_isTimeAfterNow(b.startTime));
        }).toList();
      default:
        return bookings;
    }
  }

  bool _isTimeAfterNow(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    final bookingTime = DateTime(now.year, now.month, now.day, hour, minute);
    return bookingTime.isAfter(now);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Column(
      children: [
        // Filter chips and lock button
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _selectedFilter == 'all',
                      onSelected: () {
                        setState(() {
                          _selectedFilter = 'all';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Today',
                      isSelected: _selectedFilter == 'today',
                      onSelected: () {
                        setState(() {
                          _selectedFilter = 'today';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Upcoming',
                      isSelected: _selectedFilter == 'upcoming',
                      onSelected: () {
                        setState(() {
                          _selectedFilter = 'upcoming';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Past',
                      isSelected: _selectedFilter == 'past',
                      onSelected: () {
                        setState(() {
                          _selectedFilter = 'past';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Lock/Unlock button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Tooltip(
                    message: _isLocked ? 'Unlock booking actions' : 'Lock booking actions',
                    child: IconButton(
                      icon: Icon(
                        _isLocked ? Icons.lock : Icons.lock_open,
                        size: 20,
                        color: _isLocked ? Colors.orange : Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _isLocked = !_isLocked;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isLocked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Booking actions are locked',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        // Bookings list
        Expanded(
          child: BlocConsumer<OwnerBloc, OwnerState>(
            listener: (context, state) {
              // Reload bookings when status is updated
              if (state is BookingStatusUpdated) {
                if (mounted) {
                  context.safeReadBlocAdd<OwnerBloc, LoadAllBookingsEvent>(
                    LoadAllBookingsEvent(),
                  );
                }
              }
            },
            builder: (context, state) {
              if (state is OwnerLoading) {
                return const LoadingWidget(message: 'Loading bookings...');
              }

              if (state is OwnerError) {
                return ErrorDisplayWidget(
                  message: state.message,
                  onRetry: () {
                    if (!mounted) return;
                    context.safeReadBlocAdd<OwnerBloc, LoadAllBookingsEvent>(
                      LoadAllBookingsEvent(),
                    );
                  },
                );
              }

              if (state is AllBookingsLoaded) {
                final filteredBookings = _filterBookings(state.bookings);

                if (filteredBookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _selectedFilter == 'all'
                            ? 'No bookings found'
                            : 'No ${_selectedFilter} bookings',
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (!mounted) return;
                    context.safeReadBlocAdd<OwnerBloc, LoadAllBookingsEvent>(
                      LoadAllBookingsEvent(),
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return _BookingCard(
                        booking: booking,
                        isLocked: _isLocked,
                      );
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingEntity booking;
  final bool isLocked;

  const _BookingCard({
    required this.booking,
    this.isLocked = false,
  });

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
                      if (booking.groundName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          booking.groundName!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 4),
                      if (booking.customerName != null)
                        Text(
                          'Customer: ${booking.customerName}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
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
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormatters.formatDisplayDate(booking.bookingDate),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text('${booking.startTime} (${booking.durationHours} hrs)'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rs. ${booking.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  booking.bookingCode,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                    fontSize: 12,
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
                      onPressed: isLocked
                          ? null
                          : () {
                              if (!context.mounted) return;
                              context.safeReadBlocAdd<OwnerBloc, MarkBookingStartedEvent>(
                                MarkBookingStartedEvent(booking.id),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking marked as started')),
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isLocked ? Colors.grey : null,
                      ),
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
                      onPressed: isLocked
                          ? null
                          : () {
                              if (!context.mounted) return;
                              context.safeReadBlocAdd<OwnerBloc, MarkBookingCompletedEvent>(
                                MarkBookingCompletedEvent(booking.id),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking marked as completed')),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLocked ? Colors.grey[300] : null,
                        foregroundColor: isLocked ? Colors.grey[600] : null,
                      ),
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

