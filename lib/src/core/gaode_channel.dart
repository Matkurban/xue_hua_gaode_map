import 'package:flutter/services.dart';

import 'gaode_exception.dart';

/// Invokes a method channel and maps [PlatformException] to [GaodeException].
Future<T?> invokeGaodeMethod<T>(
  MethodChannel channel,
  String method, [
  dynamic arguments,
]) async {
  try {
    return await channel.invokeMethod<T>(method, arguments);
  } on PlatformException catch (e) {
    throw GaodeException(
      e.message ?? 'Platform call failed: $method',
      code: int.tryParse(e.code),
      platformCode: e.code,
    );
  }
}
