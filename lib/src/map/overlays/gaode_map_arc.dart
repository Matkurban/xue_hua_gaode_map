import '../../core/gaode_coordinate.dart';

/// An arc overlay defined by start, passed, and end points.
class GaodeMapArc {
  const GaodeMapArc({
    required this.id,
    required this.start,
    required this.passed,
    required this.end,
    this.strokeColor = 0xFF0000FF,
    this.strokeWidth = 10,
    this.zIndex = 0,
    this.visible = true,
  });

  final String id;
  final GaodeCoordinate start;
  final GaodeCoordinate passed;
  final GaodeCoordinate end;
  final int strokeColor;
  final double strokeWidth;
  final int zIndex;
  final bool visible;

  Map<String, dynamic> toMap() => {
    'id': id,
    'start': start.toMap(),
    'passed': passed.toMap(),
    'end': end.toMap(),
    'strokeColor': strokeColor,
    'strokeWidth': strokeWidth,
    'zIndex': zIndex,
    'visible': visible,
  };
}
