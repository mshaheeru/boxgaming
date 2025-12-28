import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> signUp(String email, String password, String? name) async {
    try {
      final authResponse = await remoteDataSource.signUp(email, password, name);
      await localDataSource.saveToken(authResponse.accessToken);
      await localDataSource.saveUser(authResponse.user);
      return Right(authResponse.user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn(String email, String password) async {
    try {
      final authResponse = await remoteDataSource.signIn(email, password);
      await localDataSource.saveToken(authResponse.accessToken);
      await localDataSource.saveUser(authResponse.user);
      return Right(authResponse.user.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    // Check if token exists first
    final token = await localDataSource.getToken();
    if (token == null || token.isEmpty) {
      return Left(AuthFailure('Not authenticated'));
    }

    try {
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.saveUser(user);
      return Right(user.toEntity());
    } on ServerException catch (e) {
      // 401 means not authenticated, which is expected if token is invalid
      if (e.message.contains('Unauthorized') || e.message.contains('401')) {
        // Clear invalid token
        await localDataSource.clearToken();
        await localDataSource.clearUser();
        return Left(AuthFailure('Session expired'));
      }
      return Left(ServerFailure('Failed to get current user'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearToken();
      await localDataSource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to logout'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await remoteDataSource.changePassword(currentPassword, newPassword);
      // Refresh user to get updated requires_password_change flag
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.saveUser(user);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

