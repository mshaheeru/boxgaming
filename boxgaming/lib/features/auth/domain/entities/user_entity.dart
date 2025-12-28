import 'package:equatable/equatable.dart';

enum UserRole {
  customer,
  owner,
  admin,
}

class UserEntity extends Equatable {
  final String id;
  final String phone;
  final String? name;
  final UserRole role;
  final String? tenantId;
  final bool requiresPasswordChange;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
    this.tenantId,
    this.requiresPasswordChange = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, phone, name, role, tenantId, requiresPasswordChange, createdAt];
}


