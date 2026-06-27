import '../../core/gaode_coordinate.dart';
import '../gaode_map_image.dart';

/// A large set of point icons rendered efficiently as a single overlay.
class GaodeMapMultiPoint {
  const GaodeMapMultiPoint({
    required this.id,
    required this.points,
    required this.icon,
    this.visible = true,
  });

  final String id;
  final List<GaodeCoordinate> points;
  final GaodeMapImage icon;
  final bool visible;

  Map<String, dynamic> toMap() => {
    'id': id,
    'points': points.map((p) => p.toMap()).toList(),
    'icon': icon.toMap(),
    'visible': visible,
  };
}
