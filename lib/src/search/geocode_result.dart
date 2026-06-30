import '../core/gaode_coordinate.dart';
import '../core/gaode_exception.dart';

/// A single geocoded location (address -> coordinate).
class Geocode {
  const Geocode({
    required this.formattedAddress,
    required this.location,
    this.province,
    this.city,
    this.district,
    this.adCode,
    this.level,
  });

  final String formattedAddress;
  final GaodeCoordinate location;
  final String? province;
  final String? city;
  final String? district;
  final String? adCode;
  final String? level;

  factory Geocode.fromMap(Map<dynamic, dynamic> map) {
    final latitude = map['latitude'];
    final longitude = map['longitude'];
    if (latitude is! num || longitude is! num) {
      throw GaodeException(
        'Geocode missing coordinates: latitude=$latitude, longitude=$longitude',
      );
    }
    return Geocode(
      formattedAddress: (map['formattedAddress'] as String?) ?? '',
      location: GaodeCoordinate(
        latitude: latitude.toDouble(),
        longitude: longitude.toDouble(),
      ),
      province: map['province'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      adCode: map['adCode'] as String?,
      level: map['level'] as String?,
    );
  }

  @override
  String toString() => 'Geocode($formattedAddress)';
}

/// Result of a forward geocode (address -> coordinates) request.
class GeocodeResult {
  const GeocodeResult({required this.geocodes});

  final List<Geocode> geocodes;

  factory GeocodeResult.fromMap(Map<dynamic, dynamic> map) {
    final raw = (map['geocodes'] as List<dynamic>?) ?? const [];
    final geocodes = <Geocode>[];
    for (final entry in raw) {
      if (entry is! Map) {
        throw GaodeException('Invalid geocode entry: $entry');
      }
      geocodes.add(Geocode.fromMap(entry));
    }
    return GeocodeResult(geocodes: geocodes);
  }
}
