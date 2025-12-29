import 'package:equatable/equatable.dart';
import '../../../venues/domain/entities/venue_entity.dart';

abstract class VenueManagementState extends Equatable {
  const VenueManagementState();

  @override
  List<Object?> get props => [];
}

class VenueManagementInitial extends VenueManagementState {}

class VenueManagementLoading extends VenueManagementState {}

class VenuesLoaded extends VenueManagementState {
  final List<VenueEntity> venues;

  const VenuesLoaded(this.venues);

  @override
  List<Object?> get props => [venues];
}

class VenueCreated extends VenueManagementState {
  final VenueEntity venue;

  const VenueCreated(this.venue);

  @override
  List<Object?> get props => [venue];
}

class VenueUpdated extends VenueManagementState {
  final VenueEntity venue;

  const VenueUpdated(this.venue);

  @override
  List<Object?> get props => [venue];
}

class VenueActivated extends VenueManagementState {
  final String venueId;

  const VenueActivated(this.venueId);

  @override
  List<Object?> get props => [venueId];
}

class VenueDeactivated extends VenueManagementState {
  final String venueId;

  const VenueDeactivated(this.venueId);

  @override
  List<Object?> get props => [venueId];
}

class VenueManagementError extends VenueManagementState {
  final String message;

  const VenueManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

class PhotoUploaded extends VenueManagementState {
  final String venueId;
  final String photoUrl;

  const PhotoUploaded({
    required this.venueId,
    required this.photoUrl,
  });

  @override
  List<Object?> get props => [venueId, photoUrl];
}

