import 'camera_position.dart';
import 'gaode_map_enums.dart';

/// Initial configuration applied when the map view is created.
class GaodeMapOptions {
  const GaodeMapOptions({
    this.initialCamera,
    this.mapType = GaodeMapType.normal,
    this.myLocationEnabled = false,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
  });

  /// Where the camera starts. Defaults to Beijing if null.
  final CameraPosition? initialCamera;

  /// Map visual style.
  final GaodeMapType mapType;

  /// Whether to show the blue "my location" dot (requires location permission).
  final bool myLocationEnabled;

  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;

  Map<String, dynamic> toMap() => {
    'initialCamera': initialCamera?.toMap(),
    'mapType': mapType.wireValue,
    'myLocationEnabled': myLocationEnabled,
    'zoomGesturesEnabled': zoomGesturesEnabled,
    'scrollGesturesEnabled': scrollGesturesEnabled,
    'rotateGesturesEnabled': rotateGesturesEnabled,
    'tiltGesturesEnabled': tiltGesturesEnabled,
  };
}
