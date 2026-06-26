import 'package:flutter/services.dart';

import 'gaode_channel.dart';
import 'gaode_exception.dart';
import '../location/location_enums.dart';

/// Core SDK initialization, privacy compliance, and shared configuration.
class GaodeSdk {
  GaodeSdk._();

  static const MethodChannel _channel = MethodChannel('xue_hua_gaode_map');

  /// Must be called before any location or geofence API.
  static Future<void> updatePrivacyShow({
    required bool hasContains,
    required bool hasShow,
  }) async {
    await invokeGaodeMethod<void>(_channel, 'updatePrivacyShow', {
      'hasContains': hasContains,
      'hasShow': hasShow,
    });
  }

  /// Must be called before any location or geofence API.
  static Future<void> updatePrivacyAgree({required bool hasAgree}) async {
    await invokeGaodeMethod<void>(_channel, 'updatePrivacyAgree', {
      'hasAgree': hasAgree,
    });
  }

  static Future<void> setApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      throw GaodeException('apiKey cannot be empty');
    }
    await invokeGaodeMethod<void>(_channel, 'setApiKey', {'apiKey': apiKey});
  }

  /// Reverse geocode language. **iOS only** — uses [AMapServices.regionLanguageType].
  static Future<void> setRegionLanguage(GeoLanguage language) async {
    await invokeGaodeMethod<void>(_channel, 'setRegionLanguage', {
      'language': _geoLanguageValue(language),
    });
  }

  /// **Android only** (V11.2+) — region selection for overseas deployments.
  static Future<void> updateCountryCode(String countryCode) async {
    await invokeGaodeMethod<void>(_channel, 'updateCountryCode', {
      'countryCode': countryCode,
    });
  }

  static String _geoLanguageValue(GeoLanguage language) {
    switch (language) {
      case GeoLanguage.chinese:
        return 'chinese';
      case GeoLanguage.english:
        return 'english';
      case GeoLanguage.defaultLanguage:
        return 'default';
    }
  }
}
