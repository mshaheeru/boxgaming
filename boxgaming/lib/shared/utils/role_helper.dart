import '../../features/auth/domain/entities/user_entity.dart';

class RoleHelper {
  static bool isCustomer(UserEntity? user) {
    return user?.role == UserRole.customer;
  }

  static bool isOwner(UserEntity? user) {
    return user?.role == UserRole.owner || user?.role == UserRole.admin;
  }

  static bool isAdmin(UserEntity? user) {
    return user?.role == UserRole.admin;
  }

  static bool canAccessOwnerFeatures(UserEntity? user) {
    return isOwner(user);
  }
}


