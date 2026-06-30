import 'dart:async';

import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import '../core/gaode_client_dispose.dart';
import '../core/gaode_coordinate.dart';
import '../core/gaode_exception.dart';
import '../core/gaode_managed_event_stream.dart';
import 'location_options.dart';
import 'location_result.dart';

/// Amap location client supporting single and continuous positioning.
class LocationClient {
  LocationClient({String? clientId})
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
    'xue_hua_gaode_map/location',
  );

  final String _clientId;
  final bool _ownsClientIdReservation;
  final GaodeClientDispose _lifecycle = GaodeClientDispose();
  GaodeManagedEventStream<LocationResult>? _locationEvents;
  LocationOptions _options = const LocationOptions();

  String get clientId => _clientId;

  LocationOptions get options => _options;

  Future<void> setOptions(LocationOptions options) async {
    _ensureNotDisposed();
    _options = options;
    await invokeGaodeMethod<void>(_channel, 'location#setOptions', {
      'clientId': _clientId,
      'options': options.toMap(),
    });
  }

  /// Single-shot location request.
  Future<LocationResult> getLocation() async {
    _ensureNotDisposed();
    await setOptions(_options);
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'location#getOnce',
      {'clientId': _clientId},
    );
    if (result == null) {
      throw const GaodeException('Location returned no result');
    }
    final location = LocationResult.fromMap(result);
    location.throwIfFailed();
    return location;
  }

  /// Start continuous location updates. Listen via [locationStream].
  Future<void> start() async {
    _ensureNotDisposed();
    locationStream;
    await invokeGaodeMethod<void>(_channel, 'location#setOptions', {
      'clientId': _clientId,
      'options': _options.copyWith(onceLocation: false).toMap(),
    });
    await invokeGaodeMethod<void>(_channel, 'location#start', {
      'clientId': _clientId,
    });
  }

  Future<void> stop() async {
    if (_lifecycle.isDisposed) return;
    await invokeGaodeMethod<void>(_channel, 'location#stop', {
      'clientId': _clientId,
    });
  }

  /// Reverse geocode a coordinate without requiring a full location fix.
  Future<LocationResult> reverseGeocode(GaodeCoordinate coordinate) async {
    _ensureNotDisposed();
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'location#reverseGeocode',
      {
        'clientId': _clientId,
        'latitude': coordinate.latitude,
        'longitude': coordinate.longitude,
      },
    );
    if (result == null) {
      throw const GaodeException('Reverse geocode returned no result');
    }
    final location = LocationResult.fromMap(result);
    location.throwIfFailed();
    return location;
  }

  /// Continuous location updates.
  ///
  /// Register an [onError] handler when listening; failed native fixes are
  /// delivered as stream errors while continuous tracking keeps running.
  Stream<LocationResult> get locationStream {
    _ensureNotDisposed();
    _locationEvents ??= GaodeManagedEventStream<LocationResult>(
      channel: _eventChannel,
      arguments: _clientId,
      transform: (event) {
        if (event is! Map) {
          throw GaodeException('Invalid location event: $event');
        }
        final location = LocationResult.fromMap(event);
        if (!location.isSuccess) {
          throw GaodeException(
            location.errorInfo ?? 'Location update failed',
            code: location.errorCode,
          );
        }
        return location;
      },
    );
    return _locationEvents!.stream;
  }

  Future<void> dispose() {
    return _lifecycle.run(_disposeImpl);
  }

  Future<void> _disposeImpl() async {
    if (_lifecycle.isDisposed) return;
    await _locationEvents?.close();
    _locationEvents = null;
    await stop();
    await invokeGaodeMethod<void>(_channel, 'location#destroy', {
      'clientId': _clientId,
    });
    if (_ownsClientIdReservation) {
      _reservedClientIds.remove(_clientId);
    }
  }

  void _ensureNotDisposed() {
    _lifecycle.ensureActive('LocationClient');
  }
}
