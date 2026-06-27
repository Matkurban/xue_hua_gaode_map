/// Screen-space point in logical pixels relative to the map view.
class GaodeMapPoint {
  const GaodeMapPoint({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  factory GaodeMapPoint.fromMap(Map<dynamic, dynamic> map) {
    return GaodeMapPoint(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
    );
  }
}
