import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/owner_creation_response_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, OwnerCreationResponseEntity>> createOwner({
    required String email,
    required String tenantName,
    String? name,
    String? temporaryPassword,
  }) async {
    try {
      final response = await remoteDataSource.createOwner(
        email: email,
        tenantName: tenantName,
        name: name,
        temporaryPassword: temporaryPassword,
      );
      return Right(response.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}

