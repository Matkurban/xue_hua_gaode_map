import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_gaode_map/src/core/gaode_client_dispose.dart';

void main() {
  test('GaodeClientDispose runs teardown once', () async {
    final lifecycle = GaodeClientDispose();
    var runs = 0;
    await lifecycle.run(() async {
      runs++;
    });
    expect(runs, 1);
    expect(lifecycle.isDisposed, isTrue);
    await lifecycle.run(() async {
      runs++;
    });
    expect(runs, 1);
  });

  test('GaodeClientDispose clears cached future on failure so dispose can retry', () async {
    final lifecycle = GaodeClientDispose();
    var attempts = 0;
    Future<void> teardown() async {
      attempts++;
      if (attempts == 1) {
        throw StateError('teardown failed');
      }
    }

    await expectLater(lifecycle.run(teardown), throwsStateError);
    expect(lifecycle.isDisposed, isFalse);
    await lifecycle.run(teardown);
    expect(attempts, 2);
    expect(lifecycle.isDisposed, isTrue);
  });

  test('GaodeClientDispose concurrent dispose shares one future', () async {
    final lifecycle = GaodeClientDispose();
    var runs = 0;
    Future<void> teardown() async {
      runs++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    await Future.wait([
      lifecycle.run(teardown),
      lifecycle.run(teardown),
    ]);
    expect(runs, 1);
    expect(lifecycle.isDisposed, isTrue);
  });

  test('GaodeClientDispose ensureActive throws while disposing or disposed', () async {
    final lifecycle = GaodeClientDispose();
    final started = Completer<void>();
    final unblock = Completer<void>();

    final disposeFuture = lifecycle.run(() async {
      started.complete();
      await unblock.future;
    });

    await started.future;
    expect(() => lifecycle.ensureActive('TestClient'), throwsStateError);

    unblock.complete();
    await disposeFuture;
    expect(() => lifecycle.ensureActive('TestClient'), throwsStateError);
  });
}
