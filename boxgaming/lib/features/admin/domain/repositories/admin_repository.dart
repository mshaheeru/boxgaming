import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_creation_response_entity.dart';

abstract class AdminRepository {
  Future<Either<Failure, OwnerCreationResponseEntity>> createOwner({
    required String email,
    required String tenantName,
    String? name,
    String? temporaryPassword,
  });
}

