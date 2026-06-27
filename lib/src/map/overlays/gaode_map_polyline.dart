import '../../core/gaode_coordinate.dart';

/// A line overlay on the map.
class GaodeMapPolyline {
  const GaodeMapPolyline({
    required this.id,
    required this.points,
    this.width = 10,
    this.color = 0xFF0000FF,
    this.zIndex = 0,
    this.geodesic = false,
    this.dottedLine = false,
    this.visible = true,
  });

  final String id;
  final List<GaodeCoordinate> points;
  final double width;
  final int color;
  final int zIndex;
  final bool geodesic;
  final bool dottedLine;
  final bool visible;

  Map<String, dynamic> toMap() => {
    'id': id,
    'points': points.map((p) => p.toMap()).toList(),
    'width': width,
    'color': color,
    'zIndex': zIndex,
    'geodesic': geodesic,
    'dottedLine': dottedLine,
    'visible': visible,
  };
}
