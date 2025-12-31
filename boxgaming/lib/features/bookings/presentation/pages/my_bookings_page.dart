import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/bookings_bloc.dart';
import '../bloc/bookings_event.dart';
import '../bloc/bookings_state.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/extensions/bloc_extensions.dart';
import '../../domain/entities/booking_entity.dart';
import 'booking_detail_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load initial bookings after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBookings();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Reload bookings when app comes back to foreground
      _loadBookings();
    }
  }


  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      _loadBookings();
    }
  }

  void _loadBookings() {
    if (!mounted) return;
    final type = _tabController.index == 0 ? 'upcoming' : 'past';
    context.safeReadBlocAdd<BookingsBloc, LoadMyBookingsEvent>(
      LoadMyBookingsEvent(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookingsList(type: 'upcoming'),
          _BookingsList(type: 'past'),
        ],
      ),
    );
  }
}

class _BookingsList extends StatefulWidget {
  final String type;

  const _BookingsList({required this.type});

  @override
  State<_BookingsList> createState() => _BookingsListState();
}

class _BookingsListState extends State<_BookingsList>
    with AutomaticKeepAliveClientMixin {
  bool _hasLoaded = false;
  MyBookingsLoaded? _lastLoadedState; // Cache the last loaded state

  @override
  bool get wantKeepAlive => true; // Keep the tab alive to preserve state

  @override
  void initState() {
    super.initState();
    // Load bookings after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBookings();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload bookings when this widget becomes visible again (e.g., after navigation back)
    if (!mounted) return;
    final bloc = context.read<BookingsBloc>();
    if (bloc.isClosed) return;
    final state = bloc.state;
    
    // If state is not MyBookingsLoaded or doesn't match current tab type, reload
    if (state is! MyBookingsLoaded || state.type != widget.type) {
      // Only reload if we haven't just loaded (to avoid infinite loops)
      // Don't reload if we're loading booking details (that's a different operation)
      if (!_hasLoaded || (state is BookingDetailsLoaded || state is BookingCancelled)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadBookings();
          }
        });
      }
    }
  }

  void _loadBookings() {
    if (!mounted) return;
    _hasLoaded = true;
    context.safeReadBlocAdd<BookingsBloc, LoadMyBookingsEvent>(
      LoadMyBookingsEvent(type: widget.type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingsBloc, BookingsState>(
      listenWhen: (previous, current) {
        // Only listen to state changes that are relevant to the bookings list
        // Don't react to BookingDetailsLoaded or BookingsLoading from detail page
        return current is MyBookingsLoaded || 
               (current is BookingsError && !_hasLoaded) || 
               current is BookingCancelled;
      },
      listener: (context, state) {
        // Cache the loaded state
        if (state is MyBookingsLoaded && state.type == widget.type) {
          _hasLoaded = true;
          _lastLoadedState = state;
        }
        // If booking was cancelled, reload
        if (state is BookingCancelled) {
          _hasLoaded = false;
          _lastLoadedState = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadBookings();
            }
          });
        }
      },
      buildWhen: (previous, current) {
        // Only rebuild for states relevant to the bookings list
        // Ignore BookingDetailsLoaded and BookingsLoading from detail page operations
        if (current is BookingDetailsLoaded) {
          return false; // Don't rebuild when detail page loads
        }
        // Don't rebuild on BookingsLoading if we already have loaded state
        if (current is BookingsLoading && _lastLoadedState != null) {
          return false; // Keep showing the last loaded state
        }
        return true;
      },
      builder: (context, state) {
        // If we have a cached state and current state is loading (from detail page), use cached
        MyBookingsLoaded? displayState;
        if (state is BookingsLoading && _lastLoadedState != null) {
          displayState = _lastLoadedState!;
        } else if (state is MyBookingsLoaded) {
          displayState = state;
        } else if (_lastLoadedState != null && _lastLoadedState!.type == widget.type) {
          // Use cached state if current state is something else (like BookingDetailsLoaded)
          displayState = _lastLoadedState!;
        }

        // Show skeleton if we don't have a state to display
        if (displayState == null) {
          if (state is BookingsLoading && _lastLoadedState == null) {
            return const BookingsListSkeleton();
          }
          if (state is BookingsError) {
            return ErrorDisplayWidget(
              message: state.message,
            onRetry: () {
              if (!mounted) return;
              context.safeReadBlocAdd<BookingsBloc, LoadMyBookingsEvent>(
                LoadMyBookingsEvent(type: widget.type),
              );
            },
            );
          }
          return const SizedBox.shrink();
        }

        // At this point, displayState is guaranteed to be non-null
        final loadedState = displayState;

        // Only show bookings if they match the current tab type
        if (loadedState.type != widget.type) {
          // State doesn't match, trigger reload
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadBookings();
            }
          });
          return const BookingsListSkeleton();
        }

        if (loadedState.bookings.isEmpty) {
          return const Center(
            child: Text('No bookings found'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (!mounted) return;
            context.safeReadBlocAdd<BookingsBloc, LoadMyBookingsEvent>(
              LoadMyBookingsEvent(type: widget.type),
            );
          },
          child: ListView.builder(
            itemCount: loadedState.bookings.length,
            itemBuilder: (context, index) {
              final booking = loadedState.bookings[index];
              return RepaintBoundary(
                child: _BookingCard(booking: booking),
              );
            },
          ),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback? onTap;

  const _BookingCard({
    required this.booking,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap ?? () {
          context.push('${RouteConstants.bookingDetail}?id=${booking.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.venueName ?? 'Venue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _StatusChip(status: booking.status),
                ],
              ),
              if (booking.groundName != null) ...[
                const SizedBox(height: 4),
                Text(
                  booking.groundName!,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(booking.startTime),
                  const SizedBox(width: 8),
                  Text('(${booking.durationHours} hrs)'),
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
                    ),
                  ),
                ],
              ),
            ],
          ),
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


