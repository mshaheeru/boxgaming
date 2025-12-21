import 'package:equatable/equatable.dart';
import '../../domain/entities/venue_entity.dart';

abstract class VenuesState extends Equatable {
  const VenuesState();

  @override
  List<Object> get props => [];
}

class VenuesInitial extends VenuesState {}

class VenuesLoading extends VenuesState {}

class VenuesLoaded extends VenuesState {
  final List<VenueEntity> venues;
  final bool hasMore;
  final int currentPage;

  const VenuesLoaded({
    required this.venues,
    this.hasMore = true,
    this.currentPage = 1,
  });

  @override
  List<Object> get props => [venues, hasMore, currentPage];
}

class VenueDetailsLoaded extends VenuesState {
  final VenueEntity venue;
  final List<VenueEntity>? preservedVenuesList;
  const VenueDetailsLoaded(this.venue, {this.preservedVenuesList});

  @override
  List<Object> get props => [venue, preservedVenuesList ?? []];
}

class VenuesError extends VenuesState {
  final String message;
  const VenuesError(this.message);

  @override
  List<Object> get props => [message];
}


