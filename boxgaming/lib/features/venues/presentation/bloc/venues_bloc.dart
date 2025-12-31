import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_venues_usecase.dart';
import '../../domain/usecases/get_venue_details_usecase.dart';
import 'venues_event.dart';
import 'venues_state.dart';

class VenuesBloc extends Bloc<VenuesEvent, VenuesState> {
  final GetVenuesUseCase getVenuesUseCase;
  final GetVenueDetailsUseCase getVenueDetailsUseCase;

  VenuesBloc({
    required this.getVenuesUseCase,
    required this.getVenueDetailsUseCase,
  }) : super(VenuesInitial()) {
    on<LoadVenuesEvent>(_onLoadVenues);
    on<LoadVenueDetailsEvent>(_onLoadVenueDetails);
    on<SearchVenuesEvent>(_onSearchVenues);
  }

  Future<void> _onLoadVenues(
    LoadVenuesEvent event,
    Emitter<VenuesState> emit,
  ) async {
    if (event.refresh || state is VenuesInitial) {
      emit(VenuesLoading());
    }

    final result = await getVenuesUseCase(
      city: event.city,
      sportType: event.sportType,
      lat: event.lat,
      lng: event.lng,
      page: event.page,
      forceRefresh: event.refresh,
    );

    result.fold(
      (failure) => emit(VenuesError(failure.message)),
      (venues) {
        if (state is VenuesLoaded && !event.refresh) {
          final currentState = state as VenuesLoaded;
          // Deduplicate venues by ID when appending for pagination
          final existingIds = currentState.venues.map((v) => v.id).toSet();
          final newVenues = venues.where((v) => !existingIds.contains(v.id)).toList();
          emit(VenuesLoaded(
            venues: [...currentState.venues, ...newVenues],
            hasMore: venues.length >= 20,
            currentPage: event.page,
          ));
        } else {
          // Deduplicate venues by ID (in case backend returns duplicates)
          final seenIds = <String>{};
          final uniqueVenues = venues.where((venue) {
            if (seenIds.contains(venue.id)) {
              return false;
            }
            seenIds.add(venue.id);
            return true;
          }).toList();
          emit(VenuesLoaded(
            venues: uniqueVenues,
            hasMore: venues.length >= 20,
            currentPage: event.page,
          ));
        }
      },
    );
  }

  Future<void> _onLoadVenueDetails(
    LoadVenueDetailsEvent event,
    Emitter<VenuesState> emit,
  ) async {
    // Preserve the venues list if it exists
    final preservedVenues = state is VenuesLoaded 
        ? (state as VenuesLoaded).venues 
        : null;
    
    emit(VenuesLoading());
    final result = await getVenueDetailsUseCase(event.venueId);
    result.fold(
      (failure) => emit(VenuesError(failure.message)),
      (venue) => emit(VenueDetailsLoaded(venue, preservedVenuesList: preservedVenues)),
    );
  }

  Future<void> _onSearchVenues(
    SearchVenuesEvent event,
    Emitter<VenuesState> emit,
  ) async {
    // For now, just reload venues - can be enhanced with search API
    add(LoadVenuesEvent(refresh: true));
  }
}


