import 'package:equatable/equatable.dart';

abstract class OwnerEvent extends Equatable {
  const OwnerEvent();

  @override
  List<Object> get props => [];
}

class LoadTodayBookingsEvent extends OwnerEvent {}

class MarkBookingStartedEvent extends OwnerEvent {
  final String bookingId;
  const MarkBookingStartedEvent(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}

class MarkBookingCompletedEvent extends OwnerEvent {
  final String bookingId;
  const MarkBookingCompletedEvent(this.bookingId);

  @override
  List<Object> get props => [bookingId];
}



