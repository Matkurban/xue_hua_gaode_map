import '../../core/gaode_coordinate.dart';

/// A weighted point used by [GaodeMapHeatmap].
class GaodeHeatmapWeightedPoint {
  const GaodeHeatmapWeightedPoint({
    required this.coordinate,
    this.intensity = 1,
  });

  final GaodeCoordinate coordinate;
  final double intensity;

  Map<String, dynamic> toMap() => {
    'latitude': coordinate.latitude,
    'longitude': coordinate.longitude,
    'intensity': intensity,
  };
}

/// A heatmap overlay on the map.
class GaodeMapHeatmap {
  const GaodeMapHeatmap({
    required this.id,
    required this.points,
    this.radius = 38,
    this.opacity = 0.6,
    this.visible = true,
  });

  final String id;
  final List<GaodeHeatmapWeightedPoint> points;
  final double radius;
  final double opacity;
  final bool visible;

  Map<String, dynamic> toMap() => {
    'id': id,
    'points': points.map((p) => p.toMap()).toList(),
    'radius': radius,
    'opacity': opacity,
    'visible': visible,
  };
}
