import 'package:equatable/equatable.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class OwnerCreatedSuccess extends AdminState {
  final String email;
  final String temporaryPassword;

  const OwnerCreatedSuccess({
    required this.email,
    required this.temporaryPassword,
  });

  @override
  List<Object> get props => [email, temporaryPassword];
}

class AdminError extends AdminState {
  final String message;

  const AdminError(this.message);

  @override
  List<Object> get props => [message];
}

class AdminDashboardLoaded extends AdminState {
  final int totalTenants;
  final int totalOwners;
  final int activeVenues;
  final int totalBookings;

  const AdminDashboardLoaded({
    required this.totalTenants,
    required this.totalOwners,
    required this.activeVenues,
    required this.totalBookings,
  });

  @override
  List<Object> get props => [totalTenants, totalOwners, activeVenues, totalBookings];
}

class OwnersLoaded extends AdminState {
  final List<Map<String, dynamic>> owners;

  const OwnersLoaded(this.owners);

  @override
  List<Object> get props => [owners];
}

class PasswordResetSuccess extends AdminState {
  final String email;
  final String temporaryPassword;

  const PasswordResetSuccess({
    required this.email,
    required this.temporaryPassword,
  });

  @override
  List<Object> get props => [email, temporaryPassword];
}

