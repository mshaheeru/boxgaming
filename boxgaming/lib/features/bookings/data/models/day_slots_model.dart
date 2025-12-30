import '../../domain/entities/day_slots_entity.dart';
import '../../domain/entities/slot_entity.dart';
import 'slot_model.dart';
import '../../../../core/utils/date_formatters.dart';

class DaySlotsModel {
  final DateTime date;
  final int dayOfWeek;
  final List<SlotEntity> slots;

  const DaySlotsModel({
    required this.date,
    required this.dayOfWeek,
    required this.slots,
  });

  factory DaySlotsModel.fromJson(Map<String, dynamic> json) {
    // Parse date from string
    final dateStr = json['date'] as String? ?? json['dateStr'] as String?;
    final date = dateStr != null 
        ? DateTime.parse(dateStr)
        : DateTime.now();
    
    // Parse slots
    final slotsJson = json['slots'] as List<dynamic>? ?? [];
    final slots = slotsJson
        .whereType<Map<String, dynamic>>()
        .map((slotJson) => SlotModel.fromJson(slotJson).toEntity())
        .toList();
    
    return DaySlotsModel(
      date: date,
      dayOfWeek: json['dayOfWeek'] as int? ?? json['day_of_week'] as int? ?? 0,
      slots: slots,
    );
  }

  DaySlotsEntity toEntity() {
    return DaySlotsEntity(
      date: date,
      dayOfWeek: dayOfWeek,
      slots: slots,
    );
  }
}

