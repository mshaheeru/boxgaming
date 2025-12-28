import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_today_bookings_usecase.dart';
import '../../domain/usecases/mark_booking_started_usecase.dart';
import '../../domain/usecases/mark_booking_completed_usecase.dart';
import 'owner_event.dart';
import 'owner_state.dart';

class OwnerBloc extends Bloc<OwnerEvent, OwnerState> {
  final GetTodayBookingsUseCase getTodayBookingsUseCase;
  final MarkBookingStartedUseCase markBookingStartedUseCase;
  final MarkBookingCompletedUseCase markBookingCompletedUseCase;

  OwnerBloc({
    required this.getTodayBookingsUseCase,
    required this.markBookingStartedUseCase,
    required this.markBookingCompletedUseCase,
  }) : super(OwnerInitial()) {
    on<LoadTodayBookingsEvent>(_onLoadTodayBookings);
    on<MarkBookingStartedEvent>(_onMarkBookingStarted);
    on<MarkBookingCompletedEvent>(_onMarkBookingCompleted);
  }

  Future<void> _onLoadTodayBookings(
    LoadTodayBookingsEvent event,
    Emitter<OwnerState> emit,
  ) async {
    emit(OwnerLoading());
    final result = await getTodayBookingsUseCase();
    result.fold(
      (failure) => emit(OwnerError(failure.message)),
      (dashboard) => emit(DashboardLoaded(dashboard)),
    );
  }

  Future<void> _onMarkBookingStarted(
    MarkBookingStartedEvent event,
    Emitter<OwnerState> emit,
  ) async {
    final result = await markBookingStartedUseCase(event.bookingId);
    result.fold(
      (failure) => emit(OwnerError(failure.message)),
      (_) {
        emit(BookingStatusUpdated());
        add(LoadTodayBookingsEvent());
      },
    );
  }

  Future<void> _onMarkBookingCompleted(
    MarkBookingCompletedEvent event,
    Emitter<OwnerState> emit,
  ) async {
    final result = await markBookingCompletedUseCase(event.bookingId);
    result.fold(
      (failure) => emit(OwnerError(failure.message)),
      (_) {
        emit(BookingStatusUpdated());
        add(LoadTodayBookingsEvent());
      },
    );
  }
}



