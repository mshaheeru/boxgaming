import '../../domain/entities/operating_hours_entity.dart';

class OperatingHoursModel {
  final int dayOfWeek;
  final String openTime;
  final String closeTime;

  const OperatingHoursModel({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
  });

  factory OperatingHoursModel.fromJson(Map<String, dynamic> json) {
    return OperatingHoursModel(
      dayOfWeek: json['day_of_week'] as int? ?? json['dayOfWeek'] as int? ?? 0,
      openTime: json['open_time'] as String? ?? json['openTime'] as String? ?? '09:00',
      closeTime: json['close_time'] as String? ?? json['closeTime'] as String? ?? '22:00',
    );
  }

  OperatingHoursEntity toEntity() {
    return OperatingHoursEntity(
      dayOfWeek: dayOfWeek,
      openTime: openTime,
      closeTime: closeTime,
    );
  }
}

