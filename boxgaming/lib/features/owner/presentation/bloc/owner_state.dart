import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_entity.dart';

abstract class OwnerState extends Equatable {
  const OwnerState();

  @override
  List<Object> get props => [];
}

class OwnerInitial extends OwnerState {}

class OwnerLoading extends OwnerState {}

class DashboardLoaded extends OwnerState {
  final DashboardEntity dashboard;
  const DashboardLoaded(this.dashboard);

  @override
  List<Object> get props => [dashboard];
}

class BookingStatusUpdated extends OwnerState {}

class OwnerError extends OwnerState {
  final String message;
  const OwnerError(this.message);

  @override
  List<Object> get props => [message];
}



