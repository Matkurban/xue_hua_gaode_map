import '../gaode_map_image.dart';
import '../lat_lng_bounds.dart';

/// A ground image overlay anchored to geographic bounds.
class GaodeMapGroundOverlay {
  const GaodeMapGroundOverlay({
    required this.id,
    required this.bounds,
    required this.image,
    this.zIndex = 0,
    this.visible = true,
    this.transparency = 0,
  });

  final String id;
  final LatLngBounds bounds;
  final GaodeMapImage image;
  final int zIndex;
  final bool visible;

  /// Transparency from 0 (opaque) to 1 (fully transparent).
  final double transparency;

  Map<String, dynamic> toMap() => {
    'id': id,
    'bounds': bounds.toMap(),
    'image': image.toMap(),
    'zIndex': zIndex,
    'visible': visible,
    'transparency': transparency,
  };
}
