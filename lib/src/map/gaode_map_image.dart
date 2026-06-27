import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A PNG image passed to the native map for custom my-location icon rendering.
class GaodeMapImage {
  const GaodeMapImage({
    required this.bytes,
    this.anchor = const Offset(0.5, 0.5),
  });

  /// Raw PNG bytes.
  final Uint8List bytes;

  /// Anchor point for the icon (0–1). Used on Android only.
  final Offset anchor;

  Map<String, dynamic> toMap() => {
    'bytes': bytes,
    'anchorU': anchor.dx,
    'anchorV': anchor.dy,
  };
}
