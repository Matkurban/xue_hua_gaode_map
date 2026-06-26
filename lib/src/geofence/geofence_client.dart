import 'dart:async';

import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import '../core/gaode_coordinate.dart';
import '../core/gaode_exception.dart';
import 'geofence_action.dart';
import 'geofence_event.dart';

/// Amap geofence client for circle, polygon, POI, and district regions.
///
/// Adding fences returns immediately; success or failure is reported via
/// [geofenceStream] `createFinished` events.
class GeofenceClient {
  GeofenceClient({String? clientId})
    : _clientId = clientId ?? _nextClientId().toString();

  static int _idCounter = 0;
  static int _nextClientId() => _idCounter++;

  static const MethodChannel _channel = MethodChannel('xue_hua_gaode_map');
  static const EventChannel _eventChannel = EventChannel(
    'xue_hua_gaode_map/geofence',
  );

  final String _clientId;
  Stream<GeofenceEvent>? _geofenceStream;
  bool _disposed = false;
  Future<void>? _disposeFuture;

  String get clientId => _clientId;

  /// Configure which fence transitions emit events.
  ///
  /// Set [allowsBackgroundLocationUpdates] to `true` only when the host app
  /// has configured iOS background location modes and the required permissions.
  Future<void> setActiveActions(
    Set<GeofenceAction> actions, {
    bool allowsBackgroundLocationUpdates = false,
  }) async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#setActiveActions', {
      'clientId': _clientId,
      'actions': actions.map(_actionName).toList(),
      'allowsBackgroundLocationUpdates': allowsBackgroundLocationUpdates,
    });
  }

  /// Adds a circular geofence. Listen for [GeofenceEvent.isCreateFinished] on
  /// [geofenceStream] to learn whether creation succeeded.
  Future<void> addCircle({
    required GaodeCoordinate center,
    required double radius,
    required String customId,
  }) async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#addCircle', {
      'clientId': _clientId,
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius': radius,
      'customId': customId,
    });
  }

  /// Adds a polygon geofence. Creation result is delivered asynchronously via
  /// [geofenceStream].
  Future<void> addPolygon({
    required List<GaodeCoordinate> points,
    required String customId,
  }) async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#addPolygon', {
      'clientId': _clientId,
      'points': points.map((p) => p.toMap()).toList(),
      'customId': customId,
    });
  }

  Future<void> addPoiByKeyword({
    required String keyword,
    String poiType = '',
    String city = '',
    int size = 1,
    required String customId,
  }) async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#addPoiKeyword', {
      'clientId': _clientId,
      'keyword': keyword,
      'poiType': poiType,
      'city': city,
      'size': size,
      'customId': customId,
    });
  }

  Future<void> addPoiAround({
    required String keyword,
    required GaodeCoordinate center,
    String poiType = '',
    double aroundRadius = 3000,
    int size = 10,
    required String customId,
  }) async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#addPoiAround', {
      'clientId': _clientId,
      'keyword': keyword,
      'poiType': poiType,
      'latitude': center.latitude,
      'longitude': center.longitude,
      'aroundRadius': aroundRadius,
      'size': size,
      'customId': customId,
    });
  }

  Future<void> addDistrict({
    required String keyword,
    required String customId,
  }) async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#addDistrict', {
      'clientId': _clientId,
      'keyword': keyword,
      'customId': customId,
    });
  }

  Future<void> remove({String? customId}) async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#remove', {
      'clientId': _clientId,
      'customId': customId,
    });
  }

  Future<void> removeAll() async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#removeAll', {
      'clientId': _clientId,
    });
  }

  Future<void> pause() async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#pause', {
      'clientId': _clientId,
    });
  }

  Future<void> resume() async {
    _ensureNotDisposed();
    await invokeGaodeMethod<void>(_channel, 'geofence#resume', {
      'clientId': _clientId,
    });
  }

  Stream<GeofenceEvent> get geofenceStream {
    _ensureNotDisposed();
    _geofenceStream ??= _eventChannel.receiveBroadcastStream(_clientId).map((
      event,
    ) {
      if (event is! Map) {
        throw GaodeException('Invalid geofence event: $event');
      }
      return GeofenceEvent.fromMap(event);
    });
    return _geofenceStream!;
  }

  Future<void> dispose() {
    _disposeFuture ??= _disposeImpl();
    return _disposeFuture!;
  }

  Future<void> _disposeImpl() async {
    if (_disposed) return;
    await removeAll();
    _disposed = true;
    await invokeGaodeMethod<void>(_channel, 'geofence#destroy', {
      'clientId': _clientId,
    });
    _geofenceStream = null;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('GeofenceClient has been disposed');
    }
  }

  static String _actionName(GeofenceAction action) {
    switch (action) {
      case GeofenceAction.enter:
        return 'enter';
      case GeofenceAction.exit:
        return 'exit';
      case GeofenceAction.stayed:
        return 'stayed';
    }
  }
}
