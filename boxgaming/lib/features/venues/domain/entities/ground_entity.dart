import 'package:equatable/equatable.dart';
import 'venue_entity.dart';

enum GroundSize {
  small,
  medium,
  large,
}

class GroundEntity extends Equatable {
  final String id;
  final String venueId;
  final String name;
  final SportType sportType;
  final GroundSize size;
  final double price2hr;
  final double price3hr;
  final bool isActive;

  const GroundEntity({
    required this.id,
    required this.venueId,
    required this.name,
    required this.sportType,
    required this.size,
    required this.price2hr,
    required this.price3hr,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        venueId,
        name,
        sportType,
        size,
        price2hr,
        price3hr,
        isActive,
      ];
}



