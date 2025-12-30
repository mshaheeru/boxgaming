import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/ground_entity.dart';
import '../../domain/entities/venue_entity.dart';

part 'ground_model.g.dart';

@JsonSerializable()
class GroundModel {
  final String id;
  @JsonKey(name: 'venue_id', includeIfNull: false)
  final String? venueId;
  final String name;
  @JsonKey(name: 'sport_type')
  final String sportType;
  final String size;
  @JsonKey(name: 'price_2hr')
  final double price2hr;
  @JsonKey(name: 'price_3hr')
  final double price3hr;
  @JsonKey(name: 'is_active')
  final bool isActive;

  GroundModel({
    required this.id,
    this.venueId,
    required this.name,
    required this.sportType,
    required this.size,
    required this.price2hr,
    required this.price3hr,
    required this.isActive,
  });

  factory GroundModel.fromJson(Map<String, dynamic> json) =>
      _$GroundModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroundModelToJson(this);

  GroundEntity toEntity({String? parentVenueId}) {
    return GroundEntity(
      id: id,
      venueId: venueId ?? parentVenueId ?? '',
      name: name,
      sportType: _parseSportType(sportType),
      size: _parseSize(size),
      price2hr: price2hr,
      price3hr: price3hr,
      isActive: isActive,
    );
  }

  static SportType _parseSportType(String type) {
    switch (type) {
      case 'badminton':
        return SportType.badminton;
      case 'futsal':
        return SportType.futsal;
      case 'cricket':
        return SportType.cricket;
      case 'padel':
        return SportType.padel;
      case 'table_tennis':
        return SportType.tableTennis;
      case 'all':
        return SportType.all;
      default:
        return SportType.badminton;
    }
  }

  static GroundSize _parseSize(String size) {
    switch (size) {
      case 'small':
        return GroundSize.small;
      case 'medium':
        return GroundSize.medium;
      case 'large':
        return GroundSize.large;
      default:
        return GroundSize.medium;
    }
  }
}

