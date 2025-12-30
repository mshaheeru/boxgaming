import 'package:equatable/equatable.dart';

abstract class BookingsEvent extends Equatable {
  const BookingsEvent();

  @override
  List<Object> get props => [];
}

class LoadAvailableSlotsEvent extends BookingsEvent {
  final String groundId;
  final DateTime date;
  final int duration;

  const LoadAvailableSlotsEvent({
    required this.groundId,
    required this.date,
    required this.duration,
  });

  @override
  List<Object> get props => [groundId, date, duration];
}

class LoadOperatingHoursEvent extends BookingsEvent {
  final String venueId;
  final String groundId;

  const LoadOperatingHoursEvent({
    required this.venueId,
    required this.groundId,
  });

  @override
  List<Object> get props => [venueId, groundId];
}

class LoadSlotsForDateRangeEvent extends BookingsEvent {
  final String groundId;
  final DateTime startDate;
  final DateTime endDate;
  final int duration;

  const LoadSlotsForDateRangeEvent({
    required this.groundId,
    required this.startDate,
    required this.endDate,
    required this.duration,
  });

  @override
  List<Object> get props => [groundId, startDate, endDate, duration];
}

class CreateBookingEvent extends BookingsEvent {
  final String groundId;
  final DateTime bookingDate;
  final String startTime;
  final int durationHours;

  const CreateBookingEvent({
    required this.groundId,
    required this.bookingDate,
    required this.startTime,
    required this.durationHours,
  });

  @override
  List<Object> get props => [groundId, bookingDate, startTime, durationHours];
}

class LoadMyBookingsEvent extends BookingsEvent {
  final String type; // 'upcoming' or 'past'

  const LoadMyBookingsEvent({required this.type});

  @override
  List<Object> get props => [type];
}

class LoadBookingDetailsEvent extends BookingsEvent {
  final String bookingId;

  const LoadBookingDetailsEvent(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}

class CancelBookingEvent extends BookingsEvent {
  final String bookingId;

  const CancelBookingEvent(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}



