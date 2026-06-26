import '../core/gaode_coordinate.dart';

/// An autocomplete suggestion returned by the input tips API.
class InputTip {
  const InputTip({
    required this.name,
    this.district,
    this.adCode,
    this.location,
    this.address,
    this.poiId,
  });

  final String name;
  final String? district;
  final String? adCode;

  /// May be null for tips that are not concrete locations (e.g. bus lines).
  final GaodeCoordinate? location;
  final String? address;
  final String? poiId;

  factory InputTip.fromMap(Map<dynamic, dynamic> map) {
    final lat = map['latitude'] as num?;
    final lng = map['longitude'] as num?;
    return InputTip(
      name: (map['name'] as String?) ?? '',
      district: map['district'] as String?,
      adCode: map['adCode'] as String?,
      location: (lat != null && lng != null)
          ? GaodeCoordinate(latitude: lat.toDouble(), longitude: lng.toDouble())
          : null,
      address: map['address'] as String?,
      poiId: map['poiId'] as String?,
    );
  }

  @override
  String toString() => 'InputTip($name, $district)';
}
