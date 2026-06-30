import 'dart:async';

import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import '../core/gaode_client_dispose.dart';
import '../core/gaode_exception.dart';
import '../core/gaode_managed_event_stream.dart';
import 'offline_map_city.dart';

/// Manages offline map city packages.
///
/// Privacy compliance must be configured before calling any method.
///
/// The native offline map backend is process-wide. Multiple instances share
/// [progressStream]; the native backend is destroyed only after the last
/// instance calls [dispose].
class OfflineMapClient {
  OfflineMapClient() {
    _refCount++;
  }

  static const MethodChannel _channel = MethodChannel('xue_hua_gaode_map');
  static const EventChannel _eventChannel = EventChannel(
    'xue_hua_gaode_map/offline_map',
  );

  static int _refCount = 0;
  static GaodeManagedEventStream<OfflineMapProgressEvent>? _sharedProgressEvents;

  final GaodeClientDispose _lifecycle = GaodeClientDispose();

  /// Optional storage directory for offline map data (Android).
  ///
  /// Must be called before downloading on Android. No-op on iOS.
  Future<void> setStoragePath(String path) {
    _ensureNotDisposed();
    return invokeGaodeMethod<void>(_channel, 'offlineMap#setStoragePath', {
      'path': path,
    });
  }

  /// Returns the catalog of downloadable offline map cities.
  Future<List<OfflineMapCity>> getCityList() async {
    _ensureNotDisposed();
    final result = await invokeGaodeMethod<List<dynamic>>(
      _channel,
      'offlineMap#getCityList',
    );
    if (result == null) {
      throw const GaodeException('getCityList returned no result');
    }
    final cities = <OfflineMapCity>[];
    for (final entry in result) {
      if (entry is! Map) {
        throw GaodeException('Invalid offline map city entry: $entry');
      }
      cities.add(OfflineMapCity.fromMap(entry));
    }
    return cities;
  }

  /// Downloads the offline package for [cityCode].
  Future<void> downloadByCityCode(String cityCode) {
    _ensureNotDisposed();
    return invokeGaodeMethod<void>(_channel, 'offlineMap#downloadByCityCode', {
      'cityCode': cityCode,
    });
  }

  Future<void> downloadByCityName(String cityName) {
    _ensureNotDisposed();
    return invokeGaodeMethod<void>(_channel, 'offlineMap#downloadByCityName', {
      'cityName': cityName,
    });
  }

  /// Pauses the download for [cityCode].
  Future<void> pause(String cityCode) {
    _ensureNotDisposed();
    return invokeGaodeMethod<void>(_channel, 'offlineMap#pause', {
      'cityCode': cityCode,
    });
  }

  Future<void> resume(String cityCode) {
    _ensureNotDisposed();
    return invokeGaodeMethod<void>(_channel, 'offlineMap#resume', {
      'cityCode': cityCode,
    });
  }

  Future<void> remove(String cityCode) {
    _ensureNotDisposed();
    return invokeGaodeMethod<void>(_channel, 'offlineMap#remove', {
      'cityCode': cityCode,
    });
  }

  Future<OfflineMapCity?> getDownloadStatus(String cityCode) async {
    _ensureNotDisposed();
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'offlineMap#getDownloadStatus',
      {'cityCode': cityCode},
    );
    if (result == null || result.isEmpty) return null;
    return OfflineMapCity.fromMap(result);
  }

  Stream<OfflineMapProgressEvent> get progressStream {
    _ensureNotDisposed();
    _sharedProgressEvents ??= GaodeManagedEventStream<OfflineMapProgressEvent>(
      channel: _eventChannel,
      transform: (event) {
        if (event is! Map) {
          throw GaodeException('Invalid offline map event: $event');
        }
        return OfflineMapProgressEvent.fromMap(event);
      },
    );
    return _sharedProgressEvents!.stream;
  }

  Future<void> dispose() {
    return _lifecycle.run(_disposeImpl);
  }

  Future<void> _disposeImpl() async {
    if (_lifecycle.isDisposed) return;
    _refCount--;
    final isLastInstance = _refCount <= 0;
    try {
      if (isLastInstance) {
        _refCount = 0;
        await _sharedProgressEvents?.close();
        _sharedProgressEvents = null;
        await invokeGaodeMethod<void>(_channel, 'offlineMap#destroy');
      }
    } catch (error) {
      _refCount++;
      rethrow;
    }
  }

  void _ensureNotDisposed() {
    _lifecycle.ensureActive('OfflineMapClient');
  }
}
