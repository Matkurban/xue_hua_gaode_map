import '../core/gaode_coordinate.dart';

/// Describes the map camera: where it looks and how far it is zoomed.
class CameraPosition {
  const CameraPosition({
    required this.target,
    this.zoom = 16,
    this.bearing = 0,
    this.tilt = 0,
  });

  /// Geographic point the camera is centered on.
  final GaodeCoordinate target;

  /// Zoom level. Amap map supports roughly 3 (world) to 19 (street).
  final double zoom;

  /// Map rotation in degrees clockwise from north.
  final double bearing;

  /// Camera tilt in degrees (0 = looking straight down).
  final double tilt;

  Map<String, dynamic> toMap() => {
    'target': target.toMap(),
    'zoom': zoom,
    'bearing': bearing,
    'tilt': tilt,
  };

  factory CameraPosition.fromMap(Map<dynamic, dynamic> map) {
    return CameraPosition(
      target: GaodeCoordinate.fromMap(map['target'] as Map<dynamic, dynamic>),
      zoom: (map['zoom'] as num?)?.toDouble() ?? 16,
      bearing: (map['bearing'] as num?)?.toDouble() ?? 0,
      tilt: (map['tilt'] as num?)?.toDouble() ?? 0,
    );
  }
}
