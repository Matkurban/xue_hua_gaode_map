import 'dart:async';

import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import '../core/gaode_coordinate.dart';
import '../core/gaode_exception.dart';
import 'camera_position.dart';
import 'gaode_map_callbacks.dart';
import 'gaode_map_enums.dart';
import 'gaode_map_image.dart';
import 'gaode_map_marker.dart';
import 'gaode_map_point.dart';
import 'lat_lng_bounds.dart';
import 'overlays/gaode_map_arc.dart';
import 'overlays/gaode_map_circle.dart';
import 'overlays/gaode_map_ground_overlay.dart';
import 'overlays/gaode_map_heatmap.dart';
import 'overlays/gaode_map_multi_point.dart';
import 'overlays/gaode_map_polygon.dart';
import 'overlays/gaode_map_polyline.dart';
import 'overlays/gaode_map_tile_overlay.dart';

/// Controls a single [GaodeMapView] instance once its platform view is created.
///
/// Obtain an instance via the `onMapCreated` callback of [GaodeMapView].
class GaodeMapController {
  GaodeMapController._(this._channel, this._viewId);

  /// Internal: builds a controller bound to the per-view method channel.
  factory GaodeMapController.init(int viewId) {
    return GaodeMapController._(
      MethodChannel('xue_hua_gaode_map/map_$viewId'),
      viewId,
    );
  }

  final MethodChannel _channel;
  final int _viewId;
  Stream<GaodeMapEvent>? _events;

  /// Broadcast stream of map interaction events.
  ///
  /// [GaodeMapCameraMoveEvent] is emitted continuously while the camera moves.
  Stream<GaodeMapEvent> get events {
    _events ??= EventChannel('xue_hua_gaode_map/map_events_$_viewId')
        .receiveBroadcastStream()
        .map((event) {
          if (event is! Map) {
            throw GaodeException('Invalid map event: $event');
          }
          return GaodeMapEvent.fromMap(event);
        });
    return _events!;
  }

  // region Camera

  Future<CameraPosition> getCameraPosition() async {
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'map#getCameraPosition',
    );
    if (result == null) {
      throw const GaodeException('getCameraPosition returned no result');
    }
    return CameraPosition.fromMap(result);
  }

  Future<void> moveCamera(
    CameraPosition position, {
    bool animated = true,
  }) {
    return invokeGaodeMethod<void>(_channel, 'map#moveCamera', {
      ...position.toMap(),
      'animated': animated,
    });
  }

  Future<void> animateCamera(
    CameraPosition position, {
    int durationMs = 250,
  }) {
    return invokeGaodeMethod<void>(_channel, 'map#animateCamera', {
      ...position.toMap(),
      'durationMs': durationMs,
    });
  }

  Future<void> fitBounds(
    LatLngBounds bounds, {
    GaodeMapPadding padding = const GaodeMapPadding(),
    bool animated = true,
  }) {
    return invokeGaodeMethod<void>(_channel, 'map#fitBounds', {
      'bounds': bounds.toMap(),
      'padding': padding.toMap(),
      'animated': animated,
    });
  }

  Future<void> setMapRegionLimits(LatLngBounds? bounds) {
    return invokeGaodeMethod<void>(_channel, 'map#setMapRegionLimits', {
      'bounds': bounds?.toMap(),
    });
  }

  Future<void> zoomIn() => invokeGaodeMethod<void>(_channel, 'map#zoomIn');

  Future<void> zoomOut() => invokeGaodeMethod<void>(_channel, 'map#zoomOut');

  // endregion

  // region Display

  Future<void> setMapType(GaodeMapType mapType) {
    return invokeGaodeMethod<void>(_channel, 'map#setMapType', {
      'mapType': mapType.wireValue,
    });
  }

  Future<void> setTrafficEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setTrafficEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setBuildingsEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setBuildingsEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setMapTextEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setMapTextEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setIndoorEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setIndoorEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setCompassEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setCompassEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setScaleEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setScaleEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setLogoPosition(GaodeMapLogoPosition position) {
    return invokeGaodeMethod<void>(_channel, 'map#setLogoPosition', {
      'position': position.wireValue,
    });
  }

  Future<void> setMinMaxZoom({double? minZoom, double? maxZoom}) {
    return invokeGaodeMethod<void>(_channel, 'map#setMinMaxZoom', {
      'minZoom': minZoom,
      'maxZoom': maxZoom,
    });
  }

  Future<void> setMyLocationEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setMyLocationEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setMyLocationIcon(GaodeMapImage? icon) {
    return invokeGaodeMethod<void>(_channel, 'map#setMyLocationIcon', {
      'icon': icon?.toMap(),
    });
  }

  /// Android only. No-op on iOS.
  Future<void> setMyLocationButtonEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setMyLocationButtonEnabled', {
      'enabled': enabled,
    });
  }

  /// Android only. No-op on iOS.
  Future<void> setZoomControlsEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setZoomControlsEnabled', {
      'enabled': enabled,
    });
  }

  /// Android only. No-op on iOS.
  Future<void> setZoomControlsPosition(
    GaodeMapZoomControlsPosition position,
  ) {
    return invokeGaodeMethod<void>(_channel, 'map#setZoomControlsPosition', {
      'position': position.wireValue,
    });
  }

  // endregion

  // region Markers

  Future<void> addMarker(GaodeMapMarker marker) {
    return invokeGaodeMethod<void>(_channel, 'map#addMarker', marker.toMap());
  }

  Future<void> removeMarker(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removeMarker', {'id': id});
  }

  Future<void> clearMarkers() {
    return invokeGaodeMethod<void>(_channel, 'map#clearMarkers');
  }

  Future<void> showInfoWindow(String markerId) {
    return invokeGaodeMethod<void>(_channel, 'map#showInfoWindow', {
      'id': markerId,
    });
  }

  Future<void> hideInfoWindow(String markerId) {
    return invokeGaodeMethod<void>(_channel, 'map#hideInfoWindow', {
      'id': markerId,
    });
  }

  // endregion

  // region Overlays

  Future<void> addPolyline(GaodeMapPolyline polyline) {
    return invokeGaodeMethod<void>(_channel, 'map#addPolyline', polyline.toMap());
  }

  Future<void> removePolyline(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removePolyline', {'id': id});
  }

  Future<void> clearPolylines() {
    return invokeGaodeMethod<void>(_channel, 'map#clearPolylines');
  }

  Future<void> addPolygon(GaodeMapPolygon polygon) {
    return invokeGaodeMethod<void>(_channel, 'map#addPolygon', polygon.toMap());
  }

  Future<void> removePolygon(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removePolygon', {'id': id});
  }

  Future<void> clearPolygons() {
    return invokeGaodeMethod<void>(_channel, 'map#clearPolygons');
  }

  Future<void> addCircle(GaodeMapCircle circle) {
    return invokeGaodeMethod<void>(_channel, 'map#addCircle', circle.toMap());
  }

  Future<void> removeCircle(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removeCircle', {'id': id});
  }

  Future<void> clearCircles() {
    return invokeGaodeMethod<void>(_channel, 'map#clearCircles');
  }

  Future<void> addArc(GaodeMapArc arc) {
    return invokeGaodeMethod<void>(_channel, 'map#addArc', arc.toMap());
  }

  Future<void> removeArc(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removeArc', {'id': id});
  }

  Future<void> clearArcs() {
    return invokeGaodeMethod<void>(_channel, 'map#clearArcs');
  }

  Future<void> addGroundOverlay(GaodeMapGroundOverlay overlay) {
    return invokeGaodeMethod<void>(
      _channel,
      'map#addGroundOverlay',
      overlay.toMap(),
    );
  }

  Future<void> removeGroundOverlay(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removeGroundOverlay', {
      'id': id,
    });
  }

  Future<void> clearGroundOverlays() {
    return invokeGaodeMethod<void>(_channel, 'map#clearGroundOverlays');
  }

  Future<void> addHeatmap(GaodeMapHeatmap heatmap) {
    return invokeGaodeMethod<void>(_channel, 'map#addHeatmap', heatmap.toMap());
  }

  Future<void> removeHeatmap(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removeHeatmap', {'id': id});
  }

  Future<void> clearHeatmaps() {
    return invokeGaodeMethod<void>(_channel, 'map#clearHeatmaps');
  }

  Future<void> addMultiPoint(GaodeMapMultiPoint multiPoint) {
    return invokeGaodeMethod<void>(
      _channel,
      'map#addMultiPoint',
      multiPoint.toMap(),
    );
  }

  Future<void> removeMultiPoint(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removeMultiPoint', {
      'id': id,
    });
  }

  Future<void> clearMultiPoints() {
    return invokeGaodeMethod<void>(_channel, 'map#clearMultiPoints');
  }

  Future<void> addTileOverlay(GaodeMapTileOverlay overlay) {
    return invokeGaodeMethod<void>(
      _channel,
      'map#addTileOverlay',
      overlay.toMap(),
    );
  }

  Future<void> removeTileOverlay(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removeTileOverlay', {
      'id': id,
    });
  }

  Future<void> clearTileOverlays() {
    return invokeGaodeMethod<void>(_channel, 'map#clearTileOverlays');
  }

  Future<void> clearOverlays() {
    return invokeGaodeMethod<void>(_channel, 'map#clearOverlays');
  }

  // endregion

  // region Tools

  Future<Uint8List> takeSnapshot() async {
    final result = await invokeGaodeMethod<Uint8List>(
      _channel,
      'map#takeSnapshot',
    );
    if (result == null) {
      throw const GaodeException('takeSnapshot returned no result');
    }
    return result;
  }

  Future<GaodeMapPoint> toScreenLocation(GaodeCoordinate coordinate) async {
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'map#toScreenLocation',
      coordinate.toMap(),
    );
    if (result == null) {
      throw const GaodeException('toScreenLocation returned no result');
    }
    return GaodeMapPoint.fromMap(result);
  }

  Future<GaodeCoordinate> fromScreenLocation(GaodeMapPoint point) async {
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'map#fromScreenLocation',
      point.toMap(),
    );
    if (result == null) {
      throw const GaodeException('fromScreenLocation returned no result');
    }
    return GaodeCoordinate.fromMap(result);
  }

  // endregion
}
