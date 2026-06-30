import 'dart:async';

import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import '../core/gaode_coordinate.dart';
import '../core/gaode_exception.dart';
import '../core/gaode_managed_event_stream.dart';
import 'camera_position.dart';
import 'gaode_map_callbacks.dart';
import 'gaode_map_enums.dart';
import 'gaode_map_image.dart';
import 'gaode_my_location_style.dart';
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
  bool _isDisposed = false;
  GaodeManagedEventStream<GaodeMapEvent>? _managedEvents;

  /// Marks this controller invalid after its [GaodeMapView] is removed.
  void markDisposed() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    final events = _managedEvents;
    _managedEvents = null;
    if (events != null) {
      unawaited(events.close());
    }
  }

  void _ensureActive() {
    if (_isDisposed) {
      throw StateError('GaodeMapController is no longer valid');
    }
  }

  Future<T?> _invoke<T>(
    String method, [
    Object? arguments,
  ]) {
    _ensureActive();
    return invokeGaodeMethod<T>(_channel, method, arguments);
  }

  /// Broadcast stream of map interaction events.
  ///
  /// [GaodeMapCameraMoveEvent] is emitted continuously while the camera moves.
  Stream<GaodeMapEvent> get events {
    _ensureActive();
    _managedEvents ??= GaodeManagedEventStream<GaodeMapEvent>(
      channel: EventChannel('xue_hua_gaode_map/map_events_$_viewId'),
      transform: (event) {
        if (event is! Map) {
          throw GaodeException('Invalid map event: $event');
        }
        return GaodeMapEvent.fromMap(event);
      },
    );
    return _managedEvents!.stream;
  }

  // region Camera

  Future<CameraPosition> getCameraPosition() async {
    final result = await _invoke<Map<dynamic, dynamic>>('map#getCameraPosition');
    if (result == null) {
      throw const GaodeException('getCameraPosition returned no result');
    }
    return CameraPosition.fromMap(result);
  }

  Future<void> moveCamera(
    CameraPosition position, {
    bool animated = true,
  }) {
    return _invoke<void>('map#moveCamera', {
      ...position.toMap(),
      'animated': animated,
    });
  }

  Future<void> animateCamera(
    CameraPosition position, {
    int durationMs = 250,
  }) {
    return _invoke<void>('map#animateCamera', {
      ...position.toMap(),
      'durationMs': durationMs,
    });
  }

  Future<void> fitBounds(
    LatLngBounds bounds, {
    GaodeMapPadding padding = const GaodeMapPadding(),
    bool animated = true,
  }) {
    return _invoke<void>('map#fitBounds', {
      'bounds': bounds.toMap(),
      'padding': padding.toMap(),
      'animated': animated,
    });
  }

  Future<void> setMapRegionLimits(LatLngBounds? bounds) {
    return _invoke<void>('map#setMapRegionLimits', {
      'bounds': bounds?.toMap(),
    });
  }

  Future<void> zoomIn() => _invoke<void>('map#zoomIn');

  Future<void> zoomOut() => _invoke<void>('map#zoomOut');

  // endregion

  // region Display

  Future<void> setMapType(GaodeMapType mapType) {
    return _invoke<void>('map#setMapType', {
      'mapType': mapType.wireValue,
    });
  }

  Future<void> setTrafficEnabled(bool enabled) {
    return _invoke<void>('map#setTrafficEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setBuildingsEnabled(bool enabled) {
    return _invoke<void>('map#setBuildingsEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setMapTextEnabled(bool enabled) {
    return _invoke<void>('map#setMapTextEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setIndoorEnabled(bool enabled) {
    return _invoke<void>('map#setIndoorEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setCompassEnabled(bool enabled) {
    return _invoke<void>('map#setCompassEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setScaleEnabled(bool enabled) {
    return _invoke<void>('map#setScaleEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setLogoPosition(GaodeMapLogoPosition position) {
    return _invoke<void>('map#setLogoPosition', {
      'position': position.wireValue,
    });
  }

  Future<void> setMinMaxZoom({double? minZoom, double? maxZoom}) {
    return _invoke<void>('map#setMinMaxZoom', {
      'minZoom': minZoom,
      'maxZoom': maxZoom,
    });
  }

  Future<void> setMyLocationEnabled(bool enabled) {
    return _invoke<void>('map#setMyLocationEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setMyLocationIcon(GaodeMapImage? icon) {
    return _invoke<void>('map#setMyLocationIcon', {
      'icon': icon?.toMap(),
    });
  }

  /// Android only. No-op on iOS.
  Future<void> setMyLocationButtonEnabled(bool enabled) {
    return _invoke<void>('map#setMyLocationButtonEnabled', {
      'enabled': enabled,
    });
  }

  Future<void> setMyLocationStyle(GaodeMyLocationStyle style) {
    return _invoke<void>('map#setMyLocationStyle', {
      'style': style.toMap(),
    });
  }

  /// Returns the last known my-location fix from the map, or null if unavailable.
  Future<GaodeCoordinate?> getMyLocation() async {
    final result = await _invoke<Map<dynamic, dynamic>>('map#getMyLocation');
    if (result == null) return null;
    return GaodeCoordinate.fromMap(result);
  }

  /// Moves the camera to the current my-location fix.
  ///
  /// When no fix is cached yet, Android triggers one-shot locate mode; iOS
  /// animates to [userLocation] when available.
  Future<void> moveToMyLocation({bool animated = true}) {
    return _invoke<void>('map#moveToMyLocation', {
      'animated': animated,
    });
  }

  /// Android only. No-op on iOS.
  Future<void> setZoomControlsEnabled(bool enabled) {
    return _invoke<void>('map#setZoomControlsEnabled', {
      'enabled': enabled,
    });
  }

  /// Android only. No-op on iOS.
  Future<void> setZoomControlsPosition(
    GaodeMapZoomControlsPosition position,
  ) {
    return _invoke<void>('map#setZoomControlsPosition', {
      'position': position.wireValue,
    });
  }

  // endregion

  // region Markers

  Future<void> addMarker(GaodeMapMarker marker) {
    return _invoke<void>('map#addMarker', marker.toMap());
  }

  Future<void> removeMarker(String id) {
    return _invoke<void>('map#removeMarker', {'id': id});
  }

  Future<void> clearMarkers() {
    return _invoke<void>('map#clearMarkers');
  }

  Future<void> showInfoWindow(String markerId) {
    return _invoke<void>('map#showInfoWindow', {
      'id': markerId,
    });
  }

  Future<void> hideInfoWindow(String markerId) {
    return _invoke<void>('map#hideInfoWindow', {
      'id': markerId,
    });
  }

  // endregion

  // region Overlays

  Future<void> addPolyline(GaodeMapPolyline polyline) {
    return _invoke<void>('map#addPolyline', polyline.toMap());
  }

  Future<void> removePolyline(String id) {
    return _invoke<void>('map#removePolyline', {'id': id});
  }

  Future<void> clearPolylines() {
    return _invoke<void>('map#clearPolylines');
  }

  Future<void> addPolygon(GaodeMapPolygon polygon) {
    return _invoke<void>('map#addPolygon', polygon.toMap());
  }

  Future<void> removePolygon(String id) {
    return _invoke<void>('map#removePolygon', {'id': id});
  }

  Future<void> clearPolygons() {
    return _invoke<void>('map#clearPolygons');
  }

  Future<void> addCircle(GaodeMapCircle circle) {
    return _invoke<void>('map#addCircle', circle.toMap());
  }

  Future<void> removeCircle(String id) {
    return _invoke<void>('map#removeCircle', {'id': id});
  }

  Future<void> clearCircles() {
    return _invoke<void>('map#clearCircles');
  }

  Future<void> addArc(GaodeMapArc arc) {
    return _invoke<void>('map#addArc', arc.toMap());
  }

  Future<void> removeArc(String id) {
    return _invoke<void>('map#removeArc', {'id': id});
  }

  Future<void> clearArcs() {
    return _invoke<void>('map#clearArcs');
  }

  Future<void> addGroundOverlay(GaodeMapGroundOverlay overlay) {
    return _invoke<void>('map#addGroundOverlay', overlay.toMap());
  }

  Future<void> removeGroundOverlay(String id) {
    return _invoke<void>('map#removeGroundOverlay', {
      'id': id,
    });
  }

  Future<void> clearGroundOverlays() {
    return _invoke<void>('map#clearGroundOverlays');
  }

  Future<void> addHeatmap(GaodeMapHeatmap heatmap) {
    return _invoke<void>('map#addHeatmap', heatmap.toMap());
  }

  Future<void> removeHeatmap(String id) {
    return _invoke<void>('map#removeHeatmap', {'id': id});
  }

  Future<void> clearHeatmaps() {
    return _invoke<void>('map#clearHeatmaps');
  }

  Future<void> addMultiPoint(GaodeMapMultiPoint multiPoint) {
    return _invoke<void>('map#addMultiPoint', multiPoint.toMap());
  }

  Future<void> removeMultiPoint(String id) {
    return _invoke<void>('map#removeMultiPoint', {
      'id': id,
    });
  }

  Future<void> clearMultiPoints() {
    return _invoke<void>('map#clearMultiPoints');
  }

  Future<void> addTileOverlay(GaodeMapTileOverlay overlay) {
    return _invoke<void>('map#addTileOverlay', overlay.toMap());
  }

  Future<void> removeTileOverlay(String id) {
    return _invoke<void>('map#removeTileOverlay', {
      'id': id,
    });
  }

  Future<void> clearTileOverlays() {
    return _invoke<void>('map#clearTileOverlays');
  }

  Future<void> clearOverlays() {
    return _invoke<void>('map#clearOverlays');
  }

  // endregion

  // region Tools

  Future<Uint8List> takeSnapshot() async {
    final result = await _invoke<Uint8List>('map#takeSnapshot');
    if (result == null) {
      throw const GaodeException('takeSnapshot returned no result');
    }
    return result;
  }

  Future<GaodeMapPoint> toScreenLocation(GaodeCoordinate coordinate) async {
    final result = await _invoke<Map<dynamic, dynamic>>(
      'map#toScreenLocation',
      coordinate.toMap(),
    );
    if (result == null) {
      throw const GaodeException('toScreenLocation returned no result');
    }
    return GaodeMapPoint.fromMap(result);
  }

  Future<GaodeCoordinate> fromScreenLocation(GaodeMapPoint point) async {
    final result = await _invoke<Map<dynamic, dynamic>>(
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
