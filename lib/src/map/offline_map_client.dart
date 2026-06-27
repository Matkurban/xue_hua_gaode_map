import 'dart:async';

import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import '../core/gaode_exception.dart';
import 'offline_map_city.dart';

/// Manages offline map city packages.
///
/// Privacy compliance must be configured before calling any method.
class OfflineMapClient {
  OfflineMapClient();

  static const MethodChannel _channel = MethodChannel('xue_hua_gaode_map');
  static const EventChannel _eventChannel = EventChannel(
    'xue_hua_gaode_map/offline_map',
  );

  Stream<OfflineMapProgressEvent>? _progressStream;
  bool _disposed = false;

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
    return (result ?? const [])
        .map((e) => OfflineMapCity.fromMap(e as Map<dynamic, dynamic>))
        .toList(growable: false);
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
    _progressStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      if (event is! Map) {
        throw GaodeException('Invalid offline map event: $event');
      }
      return OfflineMapProgressEvent.fromMap(event);
    });
    return _progressStream!;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _progressStream = null;
    await invokeGaodeMethod<void>(_channel, 'offlineMap#destroy');
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('OfflineMapClient has been disposed');
    }
  }
}
