import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/slot_entity.dart';
import '../../domain/entities/operating_hours_entity.dart';
import '../../domain/entities/day_slots_entity.dart';

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

class OperatingHoursLoaded extends BookingsState {
  final List<OperatingHoursEntity> operatingHours;
  const OperatingHoursLoaded(this.operatingHours);

  @override
  List<Object> get props => [operatingHours];
}

class SlotsRangeLoaded extends BookingsState {
  final Map<String, DaySlotsEntity> slotsByDate;
  const SlotsRangeLoaded(this.slotsByDate);

  @override
  List<Object> get props => [slotsByDate];
}

class BookingCreated extends BookingsState {
  final BookingEntity booking;
  const BookingCreated(this.booking);

  @override
  List<Object> get props => [booking];
}

class MyBookingsLoaded extends BookingsState {
  final List<BookingEntity> bookings;
  final String type; // 'upcoming' or 'past'
  const MyBookingsLoaded(this.bookings, this.type);

  @override
  List<Object> get props => [bookings, type];
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



