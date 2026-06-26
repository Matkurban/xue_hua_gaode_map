/// Visual style of the 2D map surface.
enum GaodeMapType {
  /// Standard daytime vector map.
  normal,

  /// Satellite imagery.
  satellite,

  /// Night-styled vector map.
  night,
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
    }
  }
}
