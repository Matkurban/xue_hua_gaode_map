import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gaode_map_controller.dart';
import 'gaode_map_options.dart';

/// Signature for the callback invoked once the map's platform view is ready.
typedef GaodeMapCreatedCallback = void Function(GaodeMapController controller);

const String _kMapViewType = 'xue_hua_gaode_map/map';

/// Embeds a native Amap map. Privacy compliance must be configured via
/// `GaodeSdk.updatePrivacyShow`/`updatePrivacyAgree` before this widget mounts.
class GaodeMapView extends StatefulWidget {
  const GaodeMapView({
    super.key,
    this.options = const GaodeMapOptions(),
    this.onMapCreated,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
  });

  /// Initial map configuration.
  final GaodeMapOptions options;

  /// Called when the underlying platform view is created.
  final GaodeMapCreatedCallback? onMapCreated;

  /// Gesture recognizers that should compete with the platform view for
  /// gestures (useful when the map is inside a scrollable).
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  State<GaodeMapView> createState() => _GaodeMapViewState();
}

class _GaodeMapViewState extends State<GaodeMapView> {
  @override
  Widget build(BuildContext context) {
    final creationParams = widget.options.toMap();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: _kMapViewType,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _kMapViewType,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      default:
        return Center(
          child: Text(
            'GaodeMapView is only supported on Android and iOS '
            '(got $defaultTargetPlatform).',
          ),
        );
    }
  }

  void _onPlatformViewCreated(int id) {
    widget.onMapCreated?.call(GaodeMapController.init(id));
  }
}
