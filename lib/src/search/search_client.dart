import 'package:flutter/services.dart';

import '../core/gaode_channel.dart';
import '../core/gaode_coordinate.dart';
import '../core/gaode_exception.dart';
import 'geocode_result.dart';
import 'input_tip.dart';
import 'poi_search_result.dart';

/// Wraps the Amap Search SDK: POI keyword/around search, input tips and
/// forward geocoding.
///
/// Privacy compliance (`GaodeSdk.updatePrivacyShow`/`updatePrivacyAgree`) must
/// be configured before calling any method.
class SearchClient {
  const SearchClient();

  static const MethodChannel _channel = MethodChannel('xue_hua_gaode_map');

  /// Keyword POI search, optionally scoped to a [city].
  ///
  /// [page] is 1-based; [pageSize] is capped at 25 by the SDK.
  Future<PoiSearchResult> searchPoiKeyword({
    required String keyword,
    String city = '',
    String type = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    if (keyword.isEmpty) {
      throw const GaodeException('keyword cannot be empty');
    }
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'search#poiKeyword',
      {
        'keyword': keyword,
        'city': city,
        'type': type,
        'page': page,
        'pageSize': pageSize,
      },
    );
    if (result == null) {
      throw const GaodeException('POI search returned no result');
    }
    return PoiSearchResult.fromMap(result);
  }

  /// POI search around a center coordinate within [radius] meters.
  Future<PoiSearchResult> searchPoiAround({
    required GaodeCoordinate center,
    String keyword = '',
    String type = '',
    int radius = 3000,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'search#poiAround',
      {
        'latitude': center.latitude,
        'longitude': center.longitude,
        'keyword': keyword,
        'type': type,
        'radius': radius,
        'page': page,
        'pageSize': pageSize,
      },
    );
    if (result == null) {
      throw const GaodeException('POI around search returned no result');
    }
    return PoiSearchResult.fromMap(result);
  }

  /// Autocomplete suggestions for [keyword], optionally scoped to a [city].
  Future<List<InputTip>> inputTips({
    required String keyword,
    String city = '',
  }) async {
    if (keyword.isEmpty) {
      throw const GaodeException('keyword cannot be empty');
    }
    final result = await invokeGaodeMethod<List<dynamic>>(
      _channel,
      'search#inputTips',
      {'keyword': keyword, 'city': city},
    );
    if (result == null) {
      throw const GaodeException('Input tips returned no result');
    }
    final tips = <InputTip>[];
    for (final entry in result) {
      if (entry is! Map) {
        throw GaodeException('Invalid input tip entry: $entry');
      }
      tips.add(InputTip.fromMap(entry));
    }
    return tips;
  }

  /// Forward geocode: resolve a textual [address] into coordinates.
  Future<GeocodeResult> geocode({
    required String address,
    String city = '',
  }) async {
    if (address.isEmpty) {
      throw const GaodeException('address cannot be empty');
    }
    final result = await invokeGaodeMethod<Map<dynamic, dynamic>>(
      _channel,
      'search#geocode',
      {'address': address, 'city': city},
    );
    if (result == null) {
      throw const GaodeException('Geocode returned no result');
    }
    return GeocodeResult.fromMap(result);
  }
}
