import 'poi.dart';

/// Result of a POI keyword or around search.
class PoiSearchResult {
  const PoiSearchResult({
    required this.pois,
    this.count = 0,
    this.pageCount = 0,
  });

  /// POIs for the requested page.
  final List<Poi> pois;

  /// Total number of POIs across all pages.
  final int count;

  /// Total number of pages.
  final int pageCount;

  factory PoiSearchResult.fromMap(Map<dynamic, dynamic> map) {
    final rawPois = (map['pois'] as List<dynamic>?) ?? const [];
    return PoiSearchResult(
      pois: rawPois
          .map((e) => Poi.fromMap(e as Map<dynamic, dynamic>))
          .toList(growable: false),
      count: (map['count'] as num?)?.toInt() ?? 0,
      pageCount: (map['pageCount'] as num?)?.toInt() ?? 0,
    );
  }
}
