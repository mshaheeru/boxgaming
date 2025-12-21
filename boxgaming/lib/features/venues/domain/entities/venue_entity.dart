import 'package:equatable/equatable.dart';
import 'ground_entity.dart';

enum SportType {
  badminton,
  futsal,
  cricket,
  padel,
  tableTennis,
}

enum VenueStatus {
  pending,
  active,
  suspended,
}

class VenueEntity extends Equatable {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;
  final String? description;
  final List<String> photos;
  final double rating;
  final VenueStatus status;
  final DateTime createdAt;
  final List<GroundEntity> grounds;
  final int reviewCount;

  const VenueEntity({
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
    required this.reviewCount,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        city,
        lat,
        lng,
        description,
        photos,
        rating,
        status,
        createdAt,
        grounds,
        reviewCount,
      ];
}


