import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/venue_entity.dart';
import 'ground_model.dart';

part 'venue_model.g.dart';

@JsonSerializable(explicitToJson: true)
class VenueModel {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;
  final String? description;
  @JsonKey(fromJson: _photosFromJson)
  final List<String> photos;
  @JsonKey(fromJson: _ratingFromJson)
  final double rating;
  @JsonKey(defaultValue: 'pending')
  final String status;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'grounds', fromJson: _groundsFromJson)
  final List<GroundModel> grounds;
  @JsonKey(name: '_count')
  final Map<String, dynamic>? count;

  VenueModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.lat,
    this.lng,
    this.description,
    required this.photos,
    required this.rating,
    required this.status,
    required this.createdAt,
    required this.grounds,
    this.count,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) =>
      _$VenueModelFromJson(json);

  Map<String, dynamic> toJson() => _$VenueModelToJson(this);

  VenueEntity toEntity() {
    return VenueEntity(
      id: id,
      name: name,
      address: address,
      city: city,
      lat: lat,
      lng: lng,
      description: description,
      photos: photos,
      rating: rating,
      status: _parseStatus(status),
      createdAt: createdAt,
      grounds: grounds.map((g) => g.toEntity(parentVenueId: id)).toList(),
      reviewCount: count?['reviews'] as int? ?? 0,
    );
  }

  static List<String> _photosFromJson(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static List<GroundModel> _groundsFromJson(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) {
            try {
              return GroundModel.fromJson(e);
            } catch (e) {
              return null;
            }
          })
          .whereType<GroundModel>()
          .toList();
    }
    return [];
  }

  static double _ratingFromJson(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _dateTimeFromJson(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static VenueStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return VenueStatus.pending;
      case 'active':
        return VenueStatus.active;
      case 'suspended':
        return VenueStatus.suspended;
      default:
        return VenueStatus.pending;
    }
  }
}

