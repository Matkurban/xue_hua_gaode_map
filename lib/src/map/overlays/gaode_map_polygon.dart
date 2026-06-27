import '../../core/gaode_coordinate.dart';

/// A filled polygon overlay on the map.
class GaodeMapPolygon {
  const GaodeMapPolygon({
    required this.id,
    required this.points,
    this.fillColor = 0x330000FF,
    this.strokeColor = 0xFF0000FF,
    this.strokeWidth = 10,
    this.zIndex = 0,
    this.visible = true,
  });

  final String id;
  final List<GaodeCoordinate> points;
  final int fillColor;
  final int strokeColor;
  final double strokeWidth;
  final int zIndex;
  final bool visible;

  Map<String, dynamic> toMap() => {
    'id': id,
    'points': points.map((p) => p.toMap()).toList(),
    'fillColor': fillColor,
    'strokeColor': strokeColor,
    'strokeWidth': strokeWidth,
    'zIndex': zIndex,
    'visible': visible,
  };
}
