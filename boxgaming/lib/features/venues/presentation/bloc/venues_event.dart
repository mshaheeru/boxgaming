import 'package:equatable/equatable.dart';
import '../../domain/entities/venue_entity.dart';

abstract class VenuesEvent extends Equatable {
  const VenuesEvent();

  @override
  List<Object> get props => [];
}

class LoadVenuesEvent extends VenuesEvent {
  final String? search;
  final String? city;
  final SportType? sportType;
  final double? lat;
  final double? lng;
  final int page;
  final bool refresh;

  const LoadVenuesEvent({
    this.search,
    this.city,
    this.sportType,
    this.lat,
    this.lng,
    this.page = 1,
    this.refresh = false,
  });

  @override
  List<Object> get props => [search ?? '', city ?? '', sportType ?? '', lat ?? 0, lng ?? 0, page, refresh];
}

class LoadVenueDetailsEvent extends VenuesEvent {
  final String venueId;
  const LoadVenueDetailsEvent(this.venueId);

  @override
  List<Object> get props => [venueId];
}

class SearchVenuesEvent extends VenuesEvent {
  final String query;
  const SearchVenuesEvent(this.query);

  @override
  List<Object> get props => [query];
}



