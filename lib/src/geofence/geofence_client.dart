import 'dart:async';

import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import '../core/gaode_coordinate.dart';
import '../core/gaode_exception.dart';
import '../core/gaode_managed_event_stream.dart';
import 'geofence_action.dart';
import 'geofence_event.dart';

/// Amap geofence client for circle, polygon, POI, and district regions.
///
/// Adding fences returns immediately; success or failure is reported via
/// [geofenceStream] `createFinished` events.
class GeofenceClient {
  GeofenceClient({String? clientId})
    : _clientId = clientId ?? _nextClientId().toString(),
      _ownsClientIdReservation = clientId != null {
    if (_ownsClientIdReservation && !_reservedClientIds.add(clientId!)) {
      throw ArgumentError.value(clientId, 'clientId', 'is already in use');
    }
  }

  static int _idCounter = 0;
  static final Set<String> _reservedClientIds = <String>{};
  static int _nextClientId() => _idCounter++;

  static const MethodChannel _channel = MethodChannel('xue_hua_gaode_map');
  static const EventChannel _eventChannel = EventChannel(
    'xue_hua_gaode_map/geofence',
  );

  final String _clientId;
  final bool _ownsClientIdReservation;
  GaodeManagedEventStream<GeofenceEvent>? _geofenceEvents;
  bool _disposed = false;
  bool _disposing = false;
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
    geofenceStream;
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
    geofenceStream;
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
    geofenceStream;
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
    geofenceStream;
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
    geofenceStream;
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
    _geofenceEvents ??= GaodeManagedEventStream<GeofenceEvent>(
      channel: _eventChannel,
      arguments: _clientId,
      transform: (event) {
        if (event is! Map) {
          throw GaodeException('Invalid geofence event: $event');
        }
        return GeofenceEvent.fromMap(event);
      },
    );
    return _geofenceEvents!.stream;
  }

  Future<void> dispose() {
    _disposeFuture ??= _disposeImpl();
    return _disposeFuture!;
  }

  Future<void> _disposeImpl() async {
    if (_disposed) return;
    _disposing = true;
    try {
      await _geofenceEvents?.close();
      _geofenceEvents = null;
      await invokeGaodeMethod<void>(_channel, 'geofence#removeAll', {
        'clientId': _clientId,
      });
      await invokeGaodeMethod<void>(_channel, 'geofence#destroy', {
        'clientId': _clientId,
      });
      _disposed = true;
      if (_ownsClientIdReservation) {
        _reservedClientIds.remove(_clientId);
      }
    } finally {
      _disposing = false;
    }
  }

  void _ensureNotDisposed() {
    if (_disposing || _disposed) {
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
