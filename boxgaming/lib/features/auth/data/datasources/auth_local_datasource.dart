import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearToken();
  Future<void> clearUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage secureStorage;
  final LocalStorage localStorage;

  AuthLocalDataSourceImpl({
    required this.secureStorage,
    required this.localStorage,
  });

  @override
  Future<void> saveToken(String token) async {
    await secureStorage.saveToken(token);
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.getToken();
  }

  @override
  Future<void> saveUser(UserModel user) async {
    // Save user to local storage
    // For now, we'll just store the token
    // Full user persistence can be added later
  }

  @override
  Future<UserModel?> getUser() async {
    // Retrieve user from local storage
    // For now, return null - user will be fetched from API
    return null;
  }

  @override
  Future<void> clearToken() async {
    await secureStorage.clearToken();
  }

  @override
  Future<void> clearUser() async {
    await localStorage.clearUserData();
  }
}


