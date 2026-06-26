/// WGS84/GCJ-02 coordinate used across location and future map modules.
class GaodeCoordinate {
  const GaodeCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GaodeCoordinate.fromMap(Map<dynamic, dynamic> map) {
    return GaodeCoordinate(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'GaodeCoordinate($latitude, $longitude)';
}
