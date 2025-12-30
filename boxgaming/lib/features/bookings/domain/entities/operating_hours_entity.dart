import 'package:equatable/equatable.dart';

class OperatingHoursEntity extends Equatable {
  final int dayOfWeek; // 0 = Sunday, 6 = Saturday
  final String openTime; // HH:MM format
  final String closeTime; // HH:MM format

  const OperatingHoursEntity({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
  });

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  @override
  List<Object?> get props => [dayOfWeek, openTime, closeTime];
}

