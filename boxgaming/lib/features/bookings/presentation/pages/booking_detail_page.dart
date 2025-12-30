import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../bloc/bookings_bloc.dart';
import '../bloc/bookings_event.dart';
import '../bloc/bookings_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/booking_entity.dart';

class BookingDetailPage extends StatelessWidget {
  final String bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    // Use BlocProvider.value to reuse the existing BLoC instead of creating a new one
    return BlocProvider.value(
      value: context.read<BookingsBloc>(),
      child: _BookingDetailContent(bookingId: bookingId),
    );
  }
}

class _BookingDetailContent extends StatefulWidget {
  final String bookingId;

  const _BookingDetailContent({required this.bookingId});

  @override
  State<_BookingDetailContent> createState() => _BookingDetailContentState();
}

class _BookingDetailContentState extends State<_BookingDetailContent> {
  bool _hasRequestedDetails = false;

  @override
  void initState() {
    super.initState();
    // Load booking details after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<BookingsBloc>();
        if (!bloc.isClosed) {
          _hasRequestedDetails = true;
          bloc.add(LoadBookingDetailsEvent(widget.bookingId));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: BlocConsumer<BookingsBloc, BookingsState>(
        listener: (context, state) {
          if (state is BookingCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking cancelled successfully')),
            );
            if (mounted) {
              context.pop();
            }
          }
        },
        buildWhen: (previous, current) {
          // Only rebuild for states relevant to booking details
          // Don't rebuild on MyBookingsLoaded (that's for the list page) unless we've requested details
          if (current is MyBookingsLoaded && !_hasRequestedDetails) {
            return false; // Don't rebuild if we haven't requested details yet
          }
          return current is BookingsLoading ||
                 current is BookingsError ||
                 current is BookingDetailsLoaded ||
                 current is BookingCancelled;
        },
        builder: (context, state) {
          // Show loading if we're loading OR if state is not the details we want
          if (state is BookingsLoading) {
            return const LoadingWidget(message: 'Loading booking details...');
          }
          
          // If state is MyBookingsLoaded but we've requested details, show loading
          if (state is! BookingDetailsLoaded && state is! BookingsError) {
            return const LoadingWidget(message: 'Loading booking details...');
          }

          if (state is BookingsError) {
            return ErrorDisplayWidget(
              message: state.message,
              onRetry: () {
                if (!mounted) return;
                final bloc = context.read<BookingsBloc>();
                if (!bloc.isClosed) {
                  bloc.add(LoadBookingDetailsEvent(widget.bookingId));
                }
              },
            );
          }

          if (state is BookingDetailsLoaded) {
            return _BookingDetailView(booking: state.booking);
          }

          // Default: show loading while waiting for details
          return const LoadingWidget(message: 'Loading booking details...');
        },
      ),
    );
  }
}

class _BookingDetailView extends StatelessWidget {
  final BookingEntity booking;

  const _BookingDetailView({required this.booking});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          booking.venueName ?? 'Venue',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _StatusChip(status: booking.status),
                    ],
                  ),
                  if (booking.groundName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      booking.groundName!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.confirmation_number,
                    label: 'Booking Code',
                    value: booking.bookingCode,
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: DateFormatters.formatDisplayDate(booking.bookingDate),
                  ),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: '${booking.startTime} (${booking.durationHours} hours)',
                  ),
                  _InfoRow(
                    icon: Icons.attach_money,
                    label: 'Amount',
                    value: 'Rs. ${booking.price.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
          ),
          if (booking.qrCode != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: booking.qrCode!,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (booking.status == BookingStatus.confirmed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showCancelDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Cancel Booking'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (!context.mounted) return;
              final bloc = context.read<BookingsBloc>();
              if (!bloc.isClosed) {
                bloc.add(CancelBookingEvent(booking.id));
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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


