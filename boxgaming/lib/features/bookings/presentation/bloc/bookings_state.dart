import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/slot_entity.dart';

abstract class BookingsState extends Equatable {
  const BookingsState();

  @override
  List<Object> get props => [];
}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

class SlotsLoaded extends BookingsState {
  final List<SlotEntity> slots;
  const SlotsLoaded(this.slots);

  @override
  List<Object> get props => [slots];
}

class BookingCreated extends BookingsState {
  final BookingEntity booking;
  const BookingCreated(this.booking);

  @override
  List<Object> get props => [booking];
}

class MyBookingsLoaded extends BookingsState {
  final List<BookingEntity> bookings;
  const MyBookingsLoaded(this.bookings);

  @override
  List<Object> get props => [bookings];
}

class BookingDetailsLoaded extends BookingsState {
  final BookingEntity booking;
  const BookingDetailsLoaded(this.booking);

  @override
  List<Object> get props => [booking];
}

class BookingCancelled extends BookingsState {}

class BookingsError extends BookingsState {
  final String message;
  const BookingsError(this.message);

  @override
  List<Object> get props => [message];
}


