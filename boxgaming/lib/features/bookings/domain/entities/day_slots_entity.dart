import 'package:equatable/equatable.dart';
import 'slot_entity.dart';

class DaySlotsEntity extends Equatable {
  final DateTime date;
  final int dayOfWeek; // 0 = Sunday, 6 = Saturday
  final List<SlotEntity> slots;

  const DaySlotsEntity({
    required this.date,
    required this.dayOfWeek,
    required this.slots,
  });

  String get dayName {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[dayOfWeek];
  }

  @override
  List<Object?> get props => [date, dayOfWeek, slots];
}

