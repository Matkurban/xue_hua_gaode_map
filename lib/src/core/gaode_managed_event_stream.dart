import 'dart:async';

import 'package:flutter/services.dart';

/// Owns a single native [EventChannel] subscription with explicit teardown.
///
/// Call [close] during client disposal so the native event pipe is released
/// and broadcast listeners receive stream completion.
class GaodeManagedEventStream<T> {
  GaodeManagedEventStream({
    required this._channel,
    this._arguments,
    required this._transform,
  });

  final EventChannel _channel;
  final Object? _arguments;
  final T Function(dynamic event) _transform;

  final StreamController<T> _controller = StreamController<T>.broadcast();
  StreamSubscription<dynamic>? _subscription;

  Stream<T> get stream {
    _ensureListening();
    return _controller.stream;
  }

  void _ensureListening() {
    if (_subscription != null || _controller.isClosed) {
      return;
    }
    _subscription = _channel.receiveBroadcastStream(_arguments).listen(
      (dynamic event) {
        if (_controller.isClosed) {
          return;
        }
        try {
          _controller.add(_transform(event));
        } catch (error, stackTrace) {
          _controller.addError(error, stackTrace);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_controller.isClosed) {
          _controller.addError(error, stackTrace);
        }
      },
    );
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}
