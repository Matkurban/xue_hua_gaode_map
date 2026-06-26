import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import 'camera_position.dart';
import 'gaode_map_enums.dart';
import 'gaode_map_marker.dart';

/// Controls a single [GaodeMapView] instance once its platform view is created.
///
/// Obtain an instance via the `onMapCreated` callback of [GaodeMapView].
class GaodeMapController {
  GaodeMapController._(this._channel);

  /// Internal: builds a controller bound to the per-view method channel.
  factory GaodeMapController.init(int viewId) {
    return GaodeMapController._(MethodChannel('xue_hua_gaode_map/map_$viewId'));
  }

  final MethodChannel _channel;

  /// Move the camera to a new position.
  Future<void> moveCamera(CameraPosition position) {
    return invokeGaodeMethod<void>(
      _channel,
      'map#moveCamera',
      position.toMap(),
    );
  }

  /// Change the map visual style.
  Future<void> setMapType(GaodeMapType mapType) {
    return invokeGaodeMethod<void>(_channel, 'map#setMapType', {
      'mapType': mapType.wireValue,
    });
  }

  /// Toggle the blue "my location" dot.
  Future<void> setMyLocationEnabled(bool enabled) {
    return invokeGaodeMethod<void>(_channel, 'map#setMyLocationEnabled', {
      'enabled': enabled,
    });
  }

  /// Add (or replace, by id) a marker on the map.
  Future<void> addMarker(GaodeMapMarker marker) {
    return invokeGaodeMethod<void>(_channel, 'map#addMarker', marker.toMap());
  }

  /// Remove a previously added marker by id.
  Future<void> removeMarker(String id) {
    return invokeGaodeMethod<void>(_channel, 'map#removeMarker', {'id': id});
  }

  /// Remove all markers from the map.
  Future<void> clearMarkers() {
    return invokeGaodeMethod<void>(_channel, 'map#clearMarkers');
  }
}
