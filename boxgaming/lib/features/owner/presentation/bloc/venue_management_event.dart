import 'package:equatable/equatable.dart';
import '../../../venues/dto/create_venue_dto.dart';
import '../../../venues/dto/update_venue_dto.dart';

abstract class VenueManagementEvent extends Equatable {
  const VenueManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyVenuesEvent extends VenueManagementEvent {}

class CreateVenueEvent extends VenueManagementEvent {
  final CreateVenueDto dto;

  const CreateVenueEvent(this.dto);

  @override
  List<Object?> get props => [dto];
}

class UpdateVenueEvent extends VenueManagementEvent {
  final String id;
  final UpdateVenueDto dto;

  const UpdateVenueEvent(this.id, this.dto);

  @override
  List<Object?> get props => [id, dto];
}

class ActivateVenueEvent extends VenueManagementEvent {
  final String id;

  const ActivateVenueEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class DeactivateVenueEvent extends VenueManagementEvent {
  final String id;

  const DeactivateVenueEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class UploadVenuePhotoEvent extends VenueManagementEvent {
  final String venueId;
  final String photoPath;

  const UploadVenuePhotoEvent(this.venueId, this.photoPath);

  @override
  List<Object?> get props => [venueId, photoPath];
}

class CreateOperatingHoursEvent extends VenueManagementEvent {
  final String venueId;
  final List<Map<String, dynamic>> operatingHours;

  const CreateOperatingHoursEvent(this.venueId, this.operatingHours);

  @override
  List<Object?> get props => [venueId, operatingHours];
}

class CompleteVenueSetupEvent extends VenueManagementEvent {
  final String venueId;

  const CompleteVenueSetupEvent(this.venueId);

  @override
  List<Object?> get props => [venueId];
}

