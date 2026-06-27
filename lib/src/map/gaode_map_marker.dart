import 'gaode_map_image.dart';
import '../core/gaode_coordinate.dart';

/// A point annotation rendered on the map.
class GaodeMapMarker {
  const GaodeMapMarker({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
    this.icon,
    this.rotation = 0,
    this.alpha = 1,
    this.draggable = false,
    this.visible = true,
    this.flat = false,
    this.zIndex = 0,
    this.infoWindowEnabled = true,
  });

  final String id;
  final GaodeCoordinate position;
  final String? title;
  final String? snippet;
  final GaodeMapImage? icon;
  final double rotation;
  final double alpha;
  final bool draggable;
  final bool visible;
  final bool flat;
  final int zIndex;
  final bool infoWindowEnabled;

  Map<String, dynamic> toMap() => {
    'id': id,
    'position': position.toMap(),
    'title': title,
    'snippet': snippet,
    'icon': icon?.toMap(),
    'rotation': rotation,
    'alpha': alpha,
    'draggable': draggable,
    'visible': visible,
    'flat': flat,
    'zIndex': zIndex,
    'infoWindowEnabled': infoWindowEnabled,
  };
}
