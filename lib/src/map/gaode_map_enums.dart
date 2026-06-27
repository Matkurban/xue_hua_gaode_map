/// Visual style of the 2D map surface.
enum GaodeMapType {
  /// Standard daytime vector map.
  normal,

  /// Satellite imagery.
  satellite,

  /// Night-styled vector map.
  night,

  /// Navigation-oriented map style.
  navi,

  /// Bus/transit-oriented map style (Android only).
  bus,
}

/// Wire value sent to the platform side.
extension GaodeMapTypeValue on GaodeMapType {
  String get wireValue {
    switch (this) {
      case GaodeMapType.normal:
        return 'normal';
      case GaodeMapType.satellite:
        return 'satellite';
      case GaodeMapType.night:
        return 'night';
      case GaodeMapType.navi:
        return 'navi';
      case GaodeMapType.bus:
        return 'bus';
    }
  }
}

/// Preset position for the map logo watermark.
enum GaodeMapLogoPosition {
  leftBottom,
  centerBottom,
  rightBottom,
}

extension GaodeMapLogoPositionValue on GaodeMapLogoPosition {
  String get wireValue {
    switch (this) {
      case GaodeMapLogoPosition.leftBottom:
        return 'leftBottom';
      case GaodeMapLogoPosition.centerBottom:
        return 'centerBottom';
      case GaodeMapLogoPosition.rightBottom:
        return 'rightBottom';
    }
  }
}

/// Preset position for the native zoom +/- controls (Android only).
enum GaodeMapZoomControlsPosition {
  /// Right edge, top.
  rightTop,

  /// Right edge, vertical center.
  rightCenter,

  /// Right edge, bottom.
  rightBottom,
}

/// Wire value sent to the platform side.
extension GaodeMapZoomControlsPositionValue on GaodeMapZoomControlsPosition {
  String get wireValue {
    switch (this) {
      case GaodeMapZoomControlsPosition.rightTop:
        return 'rightTop';
      case GaodeMapZoomControlsPosition.rightCenter:
        return 'rightCenter';
      case GaodeMapZoomControlsPosition.rightBottom:
        return 'rightBottom';
    }
  }
}
