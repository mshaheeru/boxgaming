import '../../domain/entities/owner_creation_response_entity.dart';

class OwnerCreationResponseModel {
  final Map<String, dynamic> owner;
  final Map<String, dynamic> tenant;
  final String temporaryPassword;

  OwnerCreationResponseModel({
    required this.owner,
    required this.tenant,
    required this.temporaryPassword,
  });

  factory OwnerCreationResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      // Backend returns: { owner: {...}, tenant: {...}, temporaryPassword: "..." }
      final owner = json['owner'] as Map<String, dynamic>? ?? {};
      final tempPassword = json['temporaryPassword'] as String? ?? '';
      
      print('📦 Parsing response - Full JSON keys: ${json.keys}');
      print('📦 Owner keys: ${owner.keys}');
      print('📦 Owner email: ${owner['email']}');
      print('📦 Temporary password: $tempPassword');
      
      if (tempPassword.isEmpty) {
        print('⚠️ WARNING: Temporary password is empty!');
      }
      if (owner['email'] == null || (owner['email'] as String).isEmpty) {
        print('⚠️ WARNING: Owner email is empty!');
      }
      
      return OwnerCreationResponseModel(
        owner: owner,
        tenant: json['tenant'] as Map<String, dynamic>? ?? {},
        temporaryPassword: tempPassword,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing OwnerCreationResponseModel: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'owner': owner,
      'tenant': tenant,
      'temporaryPassword': temporaryPassword,
    };
  }

  OwnerCreationResponseEntity toEntity() {
    final email = owner['email'] as String? ?? '';
    print('📦 Converting to entity - Email: $email, TempPassword: $temporaryPassword');
    
    if (email.isEmpty) {
      print('⚠️ WARNING: Email is empty in response!');
    }
    if (temporaryPassword.isEmpty) {
      print('⚠️ WARNING: Temporary password is empty in response!');
    }
    
    return OwnerCreationResponseEntity(
      email: email,
      temporaryPassword: temporaryPassword,
    );
  }
}

