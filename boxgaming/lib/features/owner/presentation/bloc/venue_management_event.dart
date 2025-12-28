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

