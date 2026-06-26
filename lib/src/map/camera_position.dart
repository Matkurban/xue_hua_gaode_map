import '../core/gaode_coordinate.dart';

/// Describes the map camera: where it looks and how far it is zoomed.
class CameraPosition {
  const CameraPosition({required this.target, this.zoom = 16});

  /// Geographic point the camera is centered on.
  final GaodeCoordinate target;

  /// Zoom level. Amap map supports roughly 3 (world) to 19 (street).
  final double zoom;

  Map<String, dynamic> toMap() => {'target': target.toMap(), 'zoom': zoom};

  factory CameraPosition.fromMap(Map<dynamic, dynamic> map) {
    return CameraPosition(
      target: GaodeCoordinate.fromMap(map['target'] as Map<dynamic, dynamic>),
      zoom: (map['zoom'] as num?)?.toDouble() ?? 16,
    );
  }
}
