import '../core/gaode_coordinate.dart';
import 'camera_position.dart';

/// Discriminated map events emitted from the native map view.
sealed class GaodeMapEvent {
  const GaodeMapEvent();

  factory GaodeMapEvent.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String? ?? '';
    try {
      switch (type) {
      case 'tap':
        return GaodeMapTapEvent(
          coordinate: GaodeCoordinate.fromMap(
            map['coordinate'] as Map<dynamic, dynamic>,
          ),
        );
      case 'longPress':
        return GaodeMapLongPressEvent(
          coordinate: GaodeCoordinate.fromMap(
            map['coordinate'] as Map<dynamic, dynamic>,
          ),
        );
      case 'cameraMoveStart':
        return const GaodeMapCameraMoveStartEvent();
      case 'cameraMove':
        return GaodeMapCameraMoveEvent(
          position: CameraPosition.fromMap(map['position'] as Map<dynamic, dynamic>),
        );
      case 'cameraMoveEnd':
        return GaodeMapCameraMoveEndEvent(
          position: CameraPosition.fromMap(map['position'] as Map<dynamic, dynamic>),
        );
      case 'markerTap':
        return GaodeMapMarkerTapEvent(id: map['id'] as String);
      case 'markerDragStart':
        return GaodeMapMarkerDragEvent(
          id: map['id'] as String,
          position: GaodeCoordinate.fromMap(
            map['position'] as Map<dynamic, dynamic>,
          ),
          phase: GaodeMapMarkerDragPhase.start,
        );
      case 'markerDrag':
        return GaodeMapMarkerDragEvent(
          id: map['id'] as String,
          position: GaodeCoordinate.fromMap(
            map['position'] as Map<dynamic, dynamic>,
          ),
          phase: GaodeMapMarkerDragPhase.move,
        );
      case 'markerDragEnd':
        return GaodeMapMarkerDragEvent(
          id: map['id'] as String,
          position: GaodeCoordinate.fromMap(
            map['position'] as Map<dynamic, dynamic>,
          ),
          phase: GaodeMapMarkerDragPhase.end,
        );
      case 'infoWindowTap':
        return GaodeMapInfoWindowTapEvent(id: map['id'] as String);
      default:
        return GaodeMapUnknownEvent(type: type);
      }
    } catch (_) {
      return GaodeMapUnknownEvent(type: type);
    }
  }
}

class GaodeMapTapEvent extends GaodeMapEvent {
  const GaodeMapTapEvent({required this.coordinate});

  final GaodeCoordinate coordinate;
}

class GaodeMapLongPressEvent extends GaodeMapEvent {
  const GaodeMapLongPressEvent({required this.coordinate});

  final GaodeCoordinate coordinate;
}

class GaodeMapCameraMoveStartEvent extends GaodeMapEvent {
  const GaodeMapCameraMoveStartEvent();
}

class GaodeMapCameraMoveEvent extends GaodeMapEvent {
  const GaodeMapCameraMoveEvent({required this.position});

  /// Latest camera position while the map is moving.
  ///
  /// Emitted continuously during gestures on both Android and iOS.
  final CameraPosition position;
}

class GaodeMapCameraMoveEndEvent extends GaodeMapEvent {
  const GaodeMapCameraMoveEndEvent({required this.position});

  final CameraPosition position;
}

class GaodeMapMarkerTapEvent extends GaodeMapEvent {
  const GaodeMapMarkerTapEvent({required this.id});

  final String id;
}

enum GaodeMapMarkerDragPhase { start, move, end }

class GaodeMapMarkerDragEvent extends GaodeMapEvent {
  const GaodeMapMarkerDragEvent({
    required this.id,
    required this.position,
    required this.phase,
  });

  final String id;
  final GaodeCoordinate position;
  final GaodeMapMarkerDragPhase phase;
}

class GaodeMapInfoWindowTapEvent extends GaodeMapEvent {
  const GaodeMapInfoWindowTapEvent({required this.id});

  final String id;
}

class GaodeMapUnknownEvent extends GaodeMapEvent {
  const GaodeMapUnknownEvent({required this.type});

  final String type;
}
