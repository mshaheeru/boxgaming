import 'package:equatable/equatable.dart';

class SlotEntity extends Equatable {
  final String time;
  final bool available;
  final String? reason;

  const SlotEntity({
    required this.time,
    required this.available,
    this.reason,
  });

  @override
  List<Object?> get props => [time, available, reason];
}


