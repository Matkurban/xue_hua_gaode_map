import '../core/gaode_coordinate.dart';

/// A simple point annotation rendered on the map.
class GaodeMapMarker {
  const GaodeMapMarker({
    required this.id,
    required this.position,
    this.title,
    this.snippet,
  });

  /// Unique identifier used to update or remove this marker later.
  final String id;

  /// Marker location.
  final GaodeCoordinate position;

  /// Title shown in the info window when tapped.
  final String? title;

  /// Secondary text shown in the info window.
  final String? snippet;

  Map<String, dynamic> toMap() => {
    'id': id,
    'position': position.toMap(),
    'title': title,
    'snippet': snippet,
  };
}
