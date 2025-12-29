import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_my_venues_usecase.dart';
import '../../domain/usecases/create_venue_usecase.dart';
import '../../domain/usecases/update_venue_usecase.dart';
import '../../domain/usecases/activate_venue_usecase.dart';
import '../../domain/usecases/deactivate_venue_usecase.dart';
import '../../data/datasources/venue_management_remote_datasource.dart';
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
  final VenueManagementRemoteDataSource remoteDataSource;

  VenueManagementBloc({
    required this.getMyVenuesUseCase,
    required this.createVenueUseCase,
    required this.updateVenueUseCase,
    required this.activateVenueUseCase,
    required this.deactivateVenueUseCase,
    required this.remoteDataSource,
  }) : super(VenueManagementInitial()) {
    on<LoadMyVenuesEvent>(_onLoadMyVenues);
    on<CreateVenueEvent>(_onCreateVenue);
    on<UpdateVenueEvent>(_onUpdateVenue);
    on<ActivateVenueEvent>(_onActivateVenue);
    on<DeactivateVenueEvent>(_onDeactivateVenue);
    on<UploadVenuePhotoEvent>(_onUploadVenuePhoto);
    on<CreateOperatingHoursEvent>(_onCreateOperatingHours);
    on<CompleteVenueSetupEvent>(_onCompleteVenueSetup);
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

  Future<void> _onUploadVenuePhoto(
    UploadVenuePhotoEvent event,
    Emitter<VenueManagementState> emit,
  ) async {
    try {
      final file = File(event.photoPath);
      final photoUrl = await remoteDataSource.uploadVenuePhoto(event.venueId, file);
      // Photo uploaded successfully - emit success state and reload venues
      emit(PhotoUploaded(venueId: event.venueId, photoUrl: photoUrl));
      add(LoadMyVenuesEvent());
    } catch (e) {
      emit(VenueManagementError('Failed to upload photo: ${e.toString()}'));
    }
  }

  Future<void> _onCreateOperatingHours(
    CreateOperatingHoursEvent event,
    Emitter<VenueManagementState> emit,
  ) async {
    try {
      await remoteDataSource.createOperatingHours(
        event.venueId,
        event.operatingHours,
      );
      // Operating hours created successfully
    } catch (e) {
      emit(VenueManagementError('Failed to create operating hours: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteVenueSetup(
    CompleteVenueSetupEvent event,
    Emitter<VenueManagementState> emit,
  ) async {
    // Activate the venue after all setup is complete
    final result = await activateVenueUseCase(event.venueId);
    result.fold(
      (failure) => emit(VenueManagementError(failure.message)),
      (_) {
        emit(VenueActivated(event.venueId));
        add(LoadMyVenuesEvent());
      },
    );
  }
}

