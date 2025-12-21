import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/venues_bloc.dart';
import '../bloc/venues_event.dart';
import '../bloc/venues_state.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../domain/entities/venue_entity.dart';
import '../../domain/entities/ground_entity.dart';
import '../../../bookings/presentation/pages/booking_screen_page.dart';

class VenueDetailPage extends StatefulWidget {
  final String venueId;

  const VenueDetailPage({super.key, required this.venueId});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  VenueEntity? _cachedVenue;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Check if venue is already loaded in the state
    final currentState = context.read<VenuesBloc>().state;
    if (currentState is VenueDetailsLoaded && currentState.venue.id == widget.venueId) {
      _cachedVenue = currentState.venue;
      _isLoading = false;
    } else {
      // Load venue details
      _loadVenueDetails();
    }
  }

  void _loadVenueDetails() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    context.read<VenuesBloc>().add(LoadVenueDetailsEvent(widget.venueId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Details'),
      ),
      body: BlocListener<VenuesBloc, VenuesState>(
        listener: (context, state) {
          if (state is VenueDetailsLoaded && state.venue.id == widget.venueId) {
            setState(() {
              _cachedVenue = state.venue;
              _isLoading = false;
              _errorMessage = null;
            });
          } else if (state is VenuesError) {
            setState(() {
              _errorMessage = state.message;
              _isLoading = false;
            });
          } else if (state is VenuesLoading && _cachedVenue == null) {
            setState(() {
              _isLoading = true;
            });
          }
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _cachedVenue == null) {
      return const LoadingWidget(message: 'Loading venue details...');
    }

    if (_errorMessage != null && _cachedVenue == null) {
      return ErrorDisplayWidget(
        message: _errorMessage!,
        onRetry: _loadVenueDetails,
      );
    }

    if (_cachedVenue != null) {
      return _VenueDetailView(venue: _cachedVenue!);
    }

    return const SizedBox.shrink();
  }
}

class _VenueDetailView extends StatelessWidget {
  final VenueEntity venue;

  const _VenueDetailView({required this.venue});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(venue.name),
            background: venue.photos.isNotEmpty
                ? Image.network(
                    venue.photos.first,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      // Suppress error logging for 404s
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.sports_esports,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.sports_esports,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      venue.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${venue.reviewCount} reviews)',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (venue.address != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(venue.address!)),
                    ],
                  ),
                ],
                if (venue.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    venue.description!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Available Grounds',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (venue.grounds.isEmpty)
                  const Text('No grounds available')
                else
                  ...venue.grounds.map((ground) => _GroundCard(ground: ground)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (venue.grounds.isNotEmpty) {
                        context.push(
                          RouteConstants.booking,
                          extra: {
                            'ground': venue.grounds.first,
                            'venueName': venue.name,
                          },
                        );
                      }
                    },
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroundCard extends StatelessWidget {
  final GroundEntity ground;

  const _GroundCard({required this.ground});

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
                Text(
                  ground.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(ground.sportType.name),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('2 hours: '),
                Text(
                  'Rs. ${ground.price2hr.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                const Text('3 hours: '),
                Text(
                  'Rs. ${ground.price3hr.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
