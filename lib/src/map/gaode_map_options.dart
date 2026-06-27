import 'camera_position.dart';
import 'gaode_map_enums.dart';
import 'gaode_map_image.dart';
import 'gaode_my_location_style.dart';
import 'lat_lng_bounds.dart';

/// Initial configuration applied when the map view is created.
///
/// Gesture, terrain, and region limit options are applied at creation time only.
class GaodeMapOptions {
  const GaodeMapOptions({
    this.initialCamera,
    this.mapType = GaodeMapType.normal,
    this.myLocationEnabled = false,
    this.myLocationIcon,
    this.myLocationStyle = const GaodeMyLocationStyle(),
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.zoomControlsPosition = GaodeMapZoomControlsPosition.rightBottom,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.rotateGesturesEnabled = true,
    this.tiltGesturesEnabled = true,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.mapTextEnabled = true,
    this.indoorEnabled = false,
    this.terrainEnabled = false,
    this.compassEnabled = true,
    this.scaleEnabled = true,
    this.logoPosition = GaodeMapLogoPosition.leftBottom,
    this.minZoom,
    this.maxZoom,
    this.regionLimits,
  });

  final CameraPosition? initialCamera;
  final GaodeMapType mapType;
  final bool myLocationEnabled;
  final GaodeMapImage? myLocationIcon;
  final GaodeMyLocationStyle myLocationStyle;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final GaodeMapZoomControlsPosition zoomControlsPosition;
  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;
  final bool rotateGesturesEnabled;
  final bool tiltGesturesEnabled;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final bool mapTextEnabled;
  final bool indoorEnabled;

  /// Android only. Must be set before the native map view is created.
  final bool terrainEnabled;
  final bool compassEnabled;
  final bool scaleEnabled;
  final GaodeMapLogoPosition logoPosition;
  final double? minZoom;
  final double? maxZoom;
  final LatLngBounds? regionLimits;

  Map<String, dynamic> toMap() => {
    'initialCamera': initialCamera?.toMap(),
    'mapType': mapType.wireValue,
    'myLocationEnabled': myLocationEnabled,
    'myLocationIcon': myLocationIcon?.toMap(),
    'myLocationStyle': myLocationStyle.toMap(),
    'myLocationButtonEnabled': myLocationButtonEnabled,
    'zoomControlsEnabled': zoomControlsEnabled,
    'zoomControlsPosition': zoomControlsPosition.wireValue,
    'zoomGesturesEnabled': zoomGesturesEnabled,
    'scrollGesturesEnabled': scrollGesturesEnabled,
    'rotateGesturesEnabled': rotateGesturesEnabled,
    'tiltGesturesEnabled': tiltGesturesEnabled,
    'trafficEnabled': trafficEnabled,
    'buildingsEnabled': buildingsEnabled,
    'mapTextEnabled': mapTextEnabled,
    'indoorEnabled': indoorEnabled,
    'terrainEnabled': terrainEnabled,
    'compassEnabled': compassEnabled,
    'scaleEnabled': scaleEnabled,
    'logoPosition': logoPosition.wireValue,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'regionLimits': regionLimits?.toMap(),
  };
}
