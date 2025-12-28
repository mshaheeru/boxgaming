import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_creation_response_entity.dart';
import '../repositories/admin_repository.dart';

class CreateOwnerUseCase {
  final AdminRepository repository;

  CreateOwnerUseCase(this.repository);

  Future<Either<Failure, OwnerCreationResponseEntity>> call({
    required String email,
    required String tenantName,
    String? name,
    String? temporaryPassword,
  }) async {
    return await repository.createOwner(
      email: email,
      tenantName: tenantName,
      name: name,
      temporaryPassword: temporaryPassword,
    );
  }
}

