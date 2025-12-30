import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_available_slots_usecase.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/get_my_bookings_usecase.dart';
import '../../domain/usecases/get_booking_details_usecase.dart';
import '../../domain/usecases/cancel_booking_usecase.dart';
import '../../domain/usecases/get_operating_hours_usecase.dart';
import '../../domain/usecases/get_slots_for_date_range_usecase.dart';
import 'bookings_event.dart';
import 'bookings_state.dart';

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final GetAvailableSlotsUseCase getAvailableSlotsUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final GetMyBookingsUseCase getMyBookingsUseCase;
  final GetBookingDetailsUseCase getBookingDetailsUseCase;
  final CancelBookingUseCase cancelBookingUseCase;
  final GetOperatingHoursUseCase getOperatingHoursUseCase;
  final GetSlotsForDateRangeUseCase getSlotsForDateRangeUseCase;

  BookingsBloc({
    required this.getAvailableSlotsUseCase,
    required this.createBookingUseCase,
    required this.getMyBookingsUseCase,
    required this.getBookingDetailsUseCase,
    required this.cancelBookingUseCase,
    required this.getOperatingHoursUseCase,
    required this.getSlotsForDateRangeUseCase,
  }) : super(BookingsInitial()) {
    on<LoadAvailableSlotsEvent>(_onLoadAvailableSlots);
    on<CreateBookingEvent>(_onCreateBooking);
    on<LoadMyBookingsEvent>(_onLoadMyBookings);
    on<LoadBookingDetailsEvent>(_onLoadBookingDetails);
    on<CancelBookingEvent>(_onCancelBooking);
    on<LoadOperatingHoursEvent>(_onLoadOperatingHours);
    on<LoadSlotsForDateRangeEvent>(_onLoadSlotsForDateRange);
  }

  Future<void> _onLoadAvailableSlots(
    LoadAvailableSlotsEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    final result = await getAvailableSlotsUseCase(
      event.groundId,
      event.date,
      event.duration,
    );
    result.fold(
      (failure) => emit(BookingsError(failure.message)),
      (slots) => emit(SlotsLoaded(slots)),
    );
  }

  Future<void> _onCreateBooking(
    CreateBookingEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    final result = await createBookingUseCase(
      groundId: event.groundId,
      bookingDate: event.bookingDate,
      startTime: event.startTime,
      durationHours: event.durationHours,
    );
    result.fold(
      (failure) => emit(BookingsError(failure.message)),
      (booking) => emit(BookingCreated(booking)),
    );
  }

  Future<void> _onLoadMyBookings(
    LoadMyBookingsEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    final result = await getMyBookingsUseCase(event.type);
    result.fold(
      (failure) => emit(BookingsError(failure.message)),
      (bookings) => emit(MyBookingsLoaded(bookings)),
    );
  }

  Future<void> _onLoadBookingDetails(
    LoadBookingDetailsEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    final result = await getBookingDetailsUseCase(event.bookingId);
    result.fold(
      (failure) => emit(BookingsError(failure.message)),
      (booking) => emit(BookingDetailsLoaded(booking)),
    );
  }

  Future<void> _onCancelBooking(
    CancelBookingEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    final result = await cancelBookingUseCase(event.bookingId);
    result.fold(
      (failure) => emit(BookingsError(failure.message)),
      (_) => emit(BookingCancelled()),
    );
  }

  Future<void> _onLoadOperatingHours(
    LoadOperatingHoursEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    final result = await getOperatingHoursUseCase(event.venueId, event.groundId);
    result.fold(
      (failure) => emit(BookingsError(failure.message)),
      (operatingHours) => emit(OperatingHoursLoaded(operatingHours)),
    );
  }

  Future<void> _onLoadSlotsForDateRange(
    LoadSlotsForDateRangeEvent event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingsLoading());
    final result = await getSlotsForDateRangeUseCase(
      event.groundId,
      event.startDate,
      event.endDate,
      event.duration,
    );
    result.fold(
      (failure) => emit(BookingsError(failure.message)),
      (slotsByDate) => emit(SlotsRangeLoaded(slotsByDate)),
    );
  }
}



