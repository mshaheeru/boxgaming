import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/venues_bloc.dart';
import '../bloc/venues_event.dart';
import '../bloc/venues_state.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/extensions/bloc_extensions.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../domain/entities/venue_entity.dart';
import 'venue_detail_page.dart';

class VenuesListPage extends StatefulWidget {
  const VenuesListPage({super.key});

  @override
  State<VenuesListPage> createState() => _VenuesListPageState();
}

class _VenuesListPageState extends State<VenuesListPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearchVisible = false;
  String? _currentSearchQuery;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Only load if state is initial or empty
    final currentState = context.read<VenuesBloc>().state;
    if (currentState is VenuesInitial || 
        (currentState is VenuesLoaded && currentState.venues.isEmpty)) {
      context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
        const LoadVenuesEvent(),
      );
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final query = value.trim().isEmpty ? null : value.trim();
        if (query != _currentSearchQuery) {
          _currentSearchQuery = query;
          _currentPage = 1; // Reset to first page on new search
          context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
            LoadVenuesEvent(search: query, refresh: true),
          );
        }
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      } else {
        _searchController.clear();
        _currentSearchQuery = null;
        _debounceTimer?.cancel();
        context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
          const LoadVenuesEvent(refresh: true),
        );
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore) {
        _isLoadingMore = true;
        _currentPage++;
        context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
          LoadVenuesEvent(page: _currentPage),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search venues...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  ),
                ),
                onChanged: _onSearchChanged,
              )
            : const Text('VENUES'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isSearchVisible
                  ? const Color(0xFFFF1744)
                  : const Color(0xFFFF1744).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isSearchVisible ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: _toggleSearch,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: BlocConsumer<VenuesBloc, VenuesState>(
        listener: (context, state) {
          if (state is VenuesLoaded) {
            _isLoadingMore = false;
          }
        },
        builder: (context, state) {
          // Show skeleton immediately while loading (if no venues yet)
          if (state is VenuesLoading) {
            // If we have venues from previous state, show them with loading indicator
            // Otherwise show skeleton
            return const VenuesListSkeleton();
          }

          if (state is VenuesError) {
            return ErrorDisplayWidget(
              message: state.message,
              onRetry: () {
                context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
                  const LoadVenuesEvent(refresh: true),
                );
              },
            );
          }

          if (state is VenuesLoaded) {
            if (state.venues.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  _currentPage = 1;
                  context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
                  const LoadVenuesEvent(refresh: true),
                );
                },
                color: const Color(0xFFFF1744),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_esports_outlined,
                        size: 64,
                        color: const Color(0xFFFF1744).withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'NO VENUES FOUND',
                        style: GoogleFonts.audiowide(
                          fontSize: 18,
                          color: Colors.white60,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _currentPage = 1;
                context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
                  const LoadVenuesEvent(refresh: true),
                );
              },
              color: const Color(0xFFFF1744),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: state.venues.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.venues.length) {
                    // Show skeleton for loading more
                    return const VenueCardSkeleton();
                  }

                  final venue = state.venues[index];
                  return RepaintBoundary(
                    child: _VenueCard(venue: venue),
                  );
                },
              ),
            );
          }

          // If state is VenueDetailsLoaded, restore the venues list if preserved
          if (state is VenueDetailsLoaded) {
            if (state.preservedVenuesList != null && state.preservedVenuesList!.isNotEmpty) {
              // Restore the preserved venues list
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  // Emit the preserved venues list state
                  context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
                    const LoadVenuesEvent(refresh: false),
                  );
                }
              });
              // Show the preserved venues while reloading
              return RefreshIndicator(
                onRefresh: () async {
                  _currentPage = 1;
                  context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
                  const LoadVenuesEvent(refresh: true),
                );
                },
                color: const Color(0xFFFF1744),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.preservedVenuesList!.length,
                  itemBuilder: (context, index) {
                    final venue = state.preservedVenuesList![index];
                    return _VenueCard(venue: venue);
                  },
                ),
              );
            } else {
              // No preserved list, reload
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
                    const LoadVenuesEvent(refresh: false),
                  );
                }
              });
              return const VenuesListSkeleton();
            }
          }

          // If state is initial, show skeleton and trigger load
          if (state is VenuesInitial) {
            // Trigger load if not already loading
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.read<VenuesBloc>().state is VenuesInitial) {
                context.safeReadBlocAdd<VenuesBloc, LoadVenuesEvent>(
        const LoadVenuesEvent(),
      );
              }
            });
            return const VenuesListSkeleton();
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final VenueEntity venue;

  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF1744).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1744).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('${RouteConstants.venueDetail}?id=${venue.id}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with gradient overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: venue.photos.isNotEmpty
                        ? Image.network(
                            venue.photos.first,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF1A1A1A),
                                      const Color(0xFF2A2A2A),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFFF1744),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              // If network image fails, show default image
                              return Image.asset(
                                'image/venue.png',
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'image/venue.png',
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0A0A0A).withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF1744),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1744).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            venue.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Venue name
                    Text(
                      venue.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Address
                    if (venue.address != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: const Color(0xFFFF1744),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              venue.address!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Reviews count
                    Row(
                      children: [
                        Text(
                          '${venue.reviewCount} reviews',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    // Sport types
                    if (venue.grounds.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: venue.grounds
                            .take(4)
                            .map((ground) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF1744)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFFF1744)
                                          .withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    ground.sportType.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFFFF1744),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
