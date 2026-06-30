/// Coordinates idempotent client teardown with retry on failure.
///
/// Clears the in-flight dispose future when [teardown] throws so callers can
/// retry. Sets [isDisposed] only after [teardown] completes successfully.
class GaodeClientDispose {
  bool isDisposed = false;
  bool isDisposing = false;
  Future<void>? _disposeFuture;

  /// Throws [StateError] when the client is disposing or already disposed.
  void ensureActive([String clientName = 'Gaode client']) {
    if (isDisposing || isDisposed) {
      throw StateError('$clientName has been disposed');
    }
  }

  /// Runs [teardown] once; concurrent calls share the same future.
  ///
  /// Failed teardown clears the cached future so a later call can retry.
  Future<void> run(Future<void> Function() teardown) {
    if (isDisposed) {
      return Future<void>.value();
    }
    _disposeFuture ??= _runImpl(teardown);
    return _disposeFuture!;
  }

  Future<void> _runImpl(Future<void> Function() teardown) async {
    isDisposing = true;
    try {
      await teardown();
      isDisposed = true;
    } catch (error) {
      _disposeFuture = null;
      rethrow;
    } finally {
      isDisposing = false;
    }
  }
}
