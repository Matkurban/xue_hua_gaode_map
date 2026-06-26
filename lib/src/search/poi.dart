import '../core/gaode_coordinate.dart';

/// A single point of interest returned by a POI search.
class Poi {
  const Poi({
    required this.id,
    required this.name,
    this.address,
    this.location,
    this.tel,
    this.distance,
    this.type,
    this.province,
    this.city,
    this.district,
    this.adCode,
  });

  final String id;
  final String name;
  final String? address;
  final GaodeCoordinate? location;
  final String? tel;

  /// Distance in meters from the search anchor (around search only).
  final int? distance;
  final String? type;
  final String? province;
  final String? city;
  final String? district;
  final String? adCode;

  factory Poi.fromMap(Map<dynamic, dynamic> map) {
    final lat = map['latitude'] as num?;
    final lng = map['longitude'] as num?;
    return Poi(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      address: map['address'] as String?,
      location: (lat != null && lng != null)
          ? GaodeCoordinate(latitude: lat.toDouble(), longitude: lng.toDouble())
          : null,
      tel: map['tel'] as String?,
      distance: (map['distance'] as num?)?.toInt(),
      type: map['type'] as String?,
      province: map['province'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      adCode: map['adCode'] as String?,
    );
  }

  @override
  String toString() => 'Poi($name, $address)';
}
