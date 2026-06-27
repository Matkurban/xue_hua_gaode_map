import '../core/gaode_coordinate.dart';

/// Geographic bounding box defined by southwest and northeast corners.
class LatLngBounds {
  const LatLngBounds({
    required this.southwest,
    required this.northeast,
  });

  final GaodeCoordinate southwest;
  final GaodeCoordinate northeast;

  Map<String, dynamic> toMap() => {
    'southwest': southwest.toMap(),
    'northeast': northeast.toMap(),
  };

  factory LatLngBounds.fromMap(Map<dynamic, dynamic> map) {
    return LatLngBounds(
      southwest: GaodeCoordinate.fromMap(
        map['southwest'] as Map<dynamic, dynamic>,
      ),
      northeast: GaodeCoordinate.fromMap(
        map['northeast'] as Map<dynamic, dynamic>,
      ),
    );
  }
}

/// Edge insets used when fitting the camera to bounds.
class GaodeMapPadding {
  const GaodeMapPadding({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  Map<String, dynamic> toMap() => {
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };

  factory GaodeMapPadding.fromMap(Map<dynamic, dynamic> map) {
    return GaodeMapPadding(
      left: (map['left'] as num?)?.toDouble() ?? 0,
      top: (map['top'] as num?)?.toDouble() ?? 0,
      right: (map['right'] as num?)?.toDouble() ?? 0,
      bottom: (map['bottom'] as num?)?.toDouble() ?? 0,
    );
  }
}
