class UpdateVenueDto {
  final String? name;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;
  final String? description;
  final List<String>? photos;

  UpdateVenueDto({
    this.name,
    this.address,
    this.city,
    this.lat,
    this.lng,
    this.description,
    this.photos,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (address != null) map['address'] = address;
    if (city != null) map['city'] = city;
    if (lat != null) map['lat'] = lat;
    if (lng != null) map['lng'] = lng;
    if (description != null) map['description'] = description;
    if (photos != null) map['photos'] = photos;
    return map;
  }
}

