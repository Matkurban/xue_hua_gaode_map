/// Android map my-location display mode (MyLocationStyle.myLocationType).
enum GaodeMyLocationType {
  /// Locate once without moving the camera.
  show,

  /// Locate once and move the camera to the fix.
  locate,

  /// Continuous tracking with the fix centered on screen.
  follow,

  /// Continuous tracking; the map rotates with device heading.
  mapRotate,

  /// Continuous tracking; the marker rotates with device heading.
  locationRotate,

  /// Continuous tracking without centering; marker rotates with heading.
  locationRotateNoCenter,

  /// Continuous tracking without centering.
  followNoCenter,

  /// Continuous tracking without centering; map rotates with heading.
  mapRotateNoCenter,
}

extension GaodeMyLocationTypeValue on GaodeMyLocationType {
  String get wireValue {
    switch (this) {
      case GaodeMyLocationType.show:
        return 'show';
      case GaodeMyLocationType.locate:
        return 'locate';
      case GaodeMyLocationType.follow:
        return 'follow';
      case GaodeMyLocationType.mapRotate:
        return 'mapRotate';
      case GaodeMyLocationType.locationRotate:
        return 'locationRotate';
      case GaodeMyLocationType.locationRotateNoCenter:
        return 'locationRotateNoCenter';
      case GaodeMyLocationType.followNoCenter:
        return 'followNoCenter';
      case GaodeMyLocationType.mapRotateNoCenter:
        return 'mapRotateNoCenter';
    }
  }

  static GaodeMyLocationType fromWire(String? value) {
    switch (value) {
      case 'show':
        return GaodeMyLocationType.show;
      case 'locate':
        return GaodeMyLocationType.locate;
      case 'follow':
        return GaodeMyLocationType.follow;
      case 'mapRotate':
        return GaodeMyLocationType.mapRotate;
      case 'locationRotate':
        return GaodeMyLocationType.locationRotate;
      case 'followNoCenter':
        return GaodeMyLocationType.followNoCenter;
      case 'mapRotateNoCenter':
        return GaodeMyLocationType.mapRotateNoCenter;
      case 'locationRotateNoCenter':
      default:
        return GaodeMyLocationType.locationRotateNoCenter;
    }
  }
}

/// iOS map user-tracking mode (MAMapView.userTrackingMode).
enum GaodeUserTrackingMode {
  none,
  follow,
  followWithHeading,
}

extension GaodeUserTrackingModeValue on GaodeUserTrackingMode {
  String get wireValue {
    switch (this) {
      case GaodeUserTrackingMode.none:
        return 'none';
      case GaodeUserTrackingMode.follow:
        return 'follow';
      case GaodeUserTrackingMode.followWithHeading:
        return 'followWithHeading';
    }
  }

  static GaodeUserTrackingMode fromWire(String? value) {
    switch (value) {
      case 'follow':
        return GaodeUserTrackingMode.follow;
      case 'followWithHeading':
        return GaodeUserTrackingMode.followWithHeading;
      case 'none':
      default:
        return GaodeUserTrackingMode.none;
    }
  }
}

/// Styling and behaviour for the native my-location dot on the map.
class GaodeMyLocationStyle {
  const GaodeMyLocationStyle({
    this.type = GaodeMyLocationType.locationRotateNoCenter,
    this.trackingMode,
    this.interval = 1000,
    this.showMarker = true,
    this.strokeColor,
    this.fillColor,
    this.strokeWidth,
    this.showsAccuracyRing,
    this.showsHeadingIndicator,
    this.enablePulseAnimation,
    this.locationDotFillColor,
    this.locationDotBgColor,
  });

  /// Android my-location mode. Ignored on iOS when [trackingMode] is set.
  final GaodeMyLocationType type;

  /// iOS user-tracking mode. When null, derived from [type] where possible.
  final GaodeUserTrackingMode? trackingMode;

  /// Continuous-location interval in milliseconds. **Android only** (min 1000).
  final int interval;

  /// Whether to draw the location marker. **Android only** (`showMyLocation`).
  final bool showMarker;

  /// Accuracy-circle stroke color (ARGB). Android: `strokeColor`; iOS: `strokeColor`.
  final int? strokeColor;

  /// Accuracy-circle fill color (ARGB). Android: `radiusFillColor`; iOS: `fillColor`.
  final int? fillColor;

  /// Accuracy-circle stroke width in logical pixels.
  final double? strokeWidth;

  /// Whether to show the accuracy ring. **iOS only.**
  final bool? showsAccuracyRing;

  /// Whether to show the heading indicator. **iOS only.**
  final bool? showsHeadingIndicator;

  /// Whether the inner dot uses a pulse animation. **iOS only.**
  final bool? enablePulseAnimation;

  /// Default dot fill color when no custom icon is set. **iOS only.**
  final int? locationDotFillColor;

  /// Default dot background color. **iOS only.**
  final int? locationDotBgColor;

  GaodeMyLocationStyle copyWith({
    GaodeMyLocationType? type,
    GaodeUserTrackingMode? trackingMode,
    int? interval,
    bool? showMarker,
    int? strokeColor,
    int? fillColor,
    double? strokeWidth,
    bool? showsAccuracyRing,
    bool? showsHeadingIndicator,
    bool? enablePulseAnimation,
    int? locationDotFillColor,
    int? locationDotBgColor,
  }) {
    return GaodeMyLocationStyle(
      type: type ?? this.type,
      trackingMode: trackingMode ?? this.trackingMode,
      interval: interval ?? this.interval,
      showMarker: showMarker ?? this.showMarker,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      showsAccuracyRing: showsAccuracyRing ?? this.showsAccuracyRing,
      showsHeadingIndicator: showsHeadingIndicator ?? this.showsHeadingIndicator,
      enablePulseAnimation: enablePulseAnimation ?? this.enablePulseAnimation,
      locationDotFillColor: locationDotFillColor ?? this.locationDotFillColor,
      locationDotBgColor: locationDotBgColor ?? this.locationDotBgColor,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.wireValue,
    if (trackingMode != null) 'trackingMode': trackingMode!.wireValue,
    'interval': interval,
    'showMarker': showMarker,
    if (strokeColor != null) 'strokeColor': strokeColor,
    if (fillColor != null) 'fillColor': fillColor,
    if (strokeWidth != null) 'strokeWidth': strokeWidth,
    if (showsAccuracyRing != null) 'showsAccuracyRing': showsAccuracyRing,
    if (showsHeadingIndicator != null)
      'showsHeadingIndicator': showsHeadingIndicator,
    if (enablePulseAnimation != null)
      'enablePulseAnimation': enablePulseAnimation,
    if (locationDotFillColor != null)
      'locationDotFillColor': locationDotFillColor,
    if (locationDotBgColor != null) 'locationDotBgColor': locationDotBgColor,
  };

  factory GaodeMyLocationStyle.fromMap(Map<dynamic, dynamic> map) {
    return GaodeMyLocationStyle(
      type: GaodeMyLocationTypeValue.fromWire(map['type'] as String?),
      trackingMode: map['trackingMode'] != null
          ? GaodeUserTrackingModeValue.fromWire(map['trackingMode'] as String?)
          : null,
      interval: (map['interval'] as num?)?.toInt() ?? 1000,
      showMarker: map['showMarker'] as bool? ?? true,
      strokeColor: (map['strokeColor'] as num?)?.toInt(),
      fillColor: (map['fillColor'] as num?)?.toInt(),
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble(),
      showsAccuracyRing: map['showsAccuracyRing'] as bool?,
      showsHeadingIndicator: map['showsHeadingIndicator'] as bool?,
      enablePulseAnimation: map['enablePulseAnimation'] as bool?,
      locationDotFillColor: (map['locationDotFillColor'] as num?)?.toInt(),
      locationDotBgColor: (map['locationDotBgColor'] as num?)?.toInt(),
    );
  }
}
