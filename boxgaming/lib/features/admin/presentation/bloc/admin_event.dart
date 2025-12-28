import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object> get props => [];
}

class CreateOwnerEvent extends AdminEvent {
  final String email;
  final String tenantName;
  final String? name;
  final String? temporaryPassword;

  const CreateOwnerEvent({
    required this.email,
    required this.tenantName,
    this.name,
    this.temporaryPassword,
  });

  @override
  List<Object> get props => [email, tenantName, name ?? '', temporaryPassword ?? ''];
}

class LoadAdminDashboardEvent extends AdminEvent {}

class LoadOwnersEvent extends AdminEvent {}

class ResetOwnerPasswordEvent extends AdminEvent {
  final String tenantId;

  const ResetOwnerPasswordEvent({required this.tenantId});

  @override
  List<Object> get props => [tenantId];
}

