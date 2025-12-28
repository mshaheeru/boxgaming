import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_my_venues_usecase.dart';
import '../../domain/usecases/create_venue_usecase.dart';
import '../../domain/usecases/update_venue_usecase.dart';
import '../../domain/usecases/activate_venue_usecase.dart';
import '../../domain/usecases/deactivate_venue_usecase.dart';
import 'venue_management_event.dart';
import 'venue_management_state.dart';
import '../../../venues/dto/create_venue_dto.dart';
import '../../../venues/dto/update_venue_dto.dart';

class VenueManagementBloc
    extends Bloc<VenueManagementEvent, VenueManagementState> {
  final GetMyVenuesUseCase getMyVenuesUseCase;
  final CreateVenueUseCase createVenueUseCase;
  final UpdateVenueUseCase updateVenueUseCase;
  final ActivateVenueUseCase activateVenueUseCase;
  final DeactivateVenueUseCase deactivateVenueUseCase;

  VenueManagementBloc({
    required this.getMyVenuesUseCase,
    required this.createVenueUseCase,
    required this.updateVenueUseCase,
    required this.activateVenueUseCase,
    required this.deactivateVenueUseCase,
  }) : super(VenueManagementInitial()) {
    on<LoadMyVenuesEvent>(_onLoadMyVenues);
    on<CreateVenueEvent>(_onCreateVenue);
    on<UpdateVenueEvent>(_onUpdateVenue);
    on<ActivateVenueEvent>(_onActivateVenue);
    on<DeactivateVenueEvent>(_onDeactivateVenue);
  }

  Future<void> _onLoadMyVenues(
    LoadMyVenuesEvent event,
    Emitter<VenueManagementState> emit,
  ) async {
    emit(VenueManagementLoading());
    final result = await getMyVenuesUseCase();
    result.fold(
      (failure) => emit(VenueManagementError(failure.message)),
      (venues) => emit(VenuesLoaded(venues)),
    );
  }

  Future<void> _onCreateVenue(
    CreateVenueEvent event,
    Emitter<VenueManagementState> emit,
  ) async {
    emit(VenueManagementLoading());
    final result = await createVenueUseCase(event.dto);
    result.fold(
      (failure) => emit(VenueManagementError(failure.message)),
      (venue) {
        emit(VenueCreated(venue));
        add(LoadMyVenuesEvent());
      },
    );
  }

  Future<void> _onUpdateVenue(
    UpdateVenueEvent event,
    Emitter<VenueManagementState> emit,
  ) async {
    emit(VenueManagementLoading());
    final result = await updateVenueUseCase(event.id, event.dto);
    result.fold(
      (failure) => emit(VenueManagementError(failure.message)),
      (venue) {
        emit(VenueUpdated(venue));
        add(LoadMyVenuesEvent());
      },
    );
  }

  Future<void> _onActivateVenue(
    ActivateVenueEvent event,
    Emitter<VenueManagementState> emit,
  ) async {
    final result = await activateVenueUseCase(event.id);
    result.fold(
      (failure) => emit(VenueManagementError(failure.message)),
      (_) {
        emit(VenueActivated(event.id));
        add(LoadMyVenuesEvent());
      },
    );
  }

  Future<void> _onDeactivateVenue(
    DeactivateVenueEvent event,
    Emitter<VenueManagementState> emit,
  ) async {
    final result = await deactivateVenueUseCase(event.id);
    result.fold(
      (failure) => emit(VenueManagementError(failure.message)),
      (_) {
        emit(VenueDeactivated(event.id));
        add(LoadMyVenuesEvent());
      },
    );
  }
}

