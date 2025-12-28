import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final String role;
  @JsonKey(name: 'tenant_id')
  final String? tenantId;
  @JsonKey(name: 'requires_password_change')
  final bool? requiresPasswordChange;
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  UserModel({
    required this.id,
    this.phone,
    this.email,
    this.name,
    required this.role,
    this.tenantId,
    this.requiresPasswordChange,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      phone: phone ?? email ?? '',
      name: name,
      role: _parseRole(role),
      tenantId: tenantId,
      requiresPasswordChange: requiresPasswordChange ?? false,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static UserRole _parseRole(String role) {
    switch (role) {
      case 'customer':
        return UserRole.customer;
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
}

