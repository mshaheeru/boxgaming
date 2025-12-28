import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/slot_entity.dart';

part 'slot_model.g.dart';

@JsonSerializable()
class SlotModel extends SlotEntity {
  const SlotModel({
    required super.time,
    required super.available,
    super.reason,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) =>
      _$SlotModelFromJson(json);

  Map<String, dynamic> toJson() => _$SlotModelToJson(this);

  SlotEntity toEntity() {
    return SlotEntity(
      time: time,
      available: available,
      reason: reason,
    );
  }
}



