import '../../core/gaode_coordinate.dart';

/// A circle overlay on the map.
class GaodeMapCircle {
  const GaodeMapCircle({
    required this.id,
    required this.center,
    required this.radius,
    this.fillColor = 0x330000FF,
    this.strokeColor = 0xFF0000FF,
    this.strokeWidth = 10,
    this.zIndex = 0,
    this.visible = true,
  });

  final String id;
  final GaodeCoordinate center;
  final double radius;
  final int fillColor;
  final int strokeColor;
  final double strokeWidth;
  final int zIndex;
  final bool visible;

  Map<String, dynamic> toMap() => {
    'id': id,
    'center': center.toMap(),
    'radius': radius,
    'fillColor': fillColor,
    'strokeColor': strokeColor,
    'strokeWidth': strokeWidth,
    'zIndex': zIndex,
    'visible': visible,
  };
}
