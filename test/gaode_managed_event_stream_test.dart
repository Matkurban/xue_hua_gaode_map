import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xue_hua_gaode_map/src/core/gaode_exception.dart';
import 'package:xue_hua_gaode_map/src/core/gaode_managed_event_stream.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const codec = StandardMethodCodec();
  const channelName = 'test_managed_event_stream';

  void setEventChannelHandler({
    required void Function(
      void Function(dynamic event) onEvent,
      void Function(Object error, StackTrace stackTrace) onError,
    )
    onListen,
    void Function()? onCancel,
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(channelName, (ByteData? message) async {
      final call = codec.decodeMethodCall(message!);
      switch (call.method) {
        case 'listen':
          final controller = StreamController<dynamic>.broadcast();
          onListen(
            controller.add,
            (error, stackTrace) => controller.addError(error, stackTrace),
          );
          controller.stream.listen(
            (event) {
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                  .handlePlatformMessage(
                channelName,
                codec.encodeSuccessEnvelope(event),
                (_) {},
              );
            },
            onError: (Object error, StackTrace stackTrace) {
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
                  .handlePlatformMessage(
                channelName,
                codec.encodeErrorEnvelope(
                  code: 'error',
                  message: error.toString(),
                  details: null,
                ),
                (_) {},
              );
            },
          );
          return codec.encodeSuccessEnvelope(null);
        case 'cancel':
          onCancel?.call();
          return codec.encodeSuccessEnvelope(null);
      }
      return null;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(channelName, null);
  });

  test('GaodeManagedEventStream delivers transformed events', () async {
    late void Function(dynamic event) emit;
    setEventChannelHandler(
      onListen: (onEvent, _) => emit = onEvent,
    );

    final managed = GaodeManagedEventStream<int>(
      channel: const EventChannel(channelName),
      transform: (event) => event as int,
    );

    final events = <int>[];
    managed.stream.listen(events.add);
    emit(1);
    emit(2);

    await Future<void>.delayed(Duration.zero);
    expect(events, [1, 2]);
    await managed.close();
  });

  test('GaodeManagedEventStream close completes listeners', () async {
    setEventChannelHandler(onListen: (_, _) {});

    final managed = GaodeManagedEventStream<int>(
      channel: const EventChannel(channelName),
      transform: (event) => event as int,
    );

    final done = Completer<void>();
    managed.stream.listen(null, onDone: done.complete);
    await managed.close();
    await done.future.timeout(const Duration(seconds: 1));
  });

  test('GaodeManagedEventStream propagates transform errors', () async {
    late void Function(dynamic event) emit;
    setEventChannelHandler(
      onListen: (onEvent, _) => emit = onEvent,
    );

    final managed = GaodeManagedEventStream<int>(
      channel: const EventChannel(channelName),
      transform: (event) {
        throw GaodeException('bad event: $event');
      },
    );

    final error = Completer<Object>();
    managed.stream.listen(
      null,
      onError: error.complete,
    );
    emit({'type': 'bad'});
    await expectLater(
      error.future,
      completion(isA<GaodeException>()),
    );
    await managed.close();
  });

  test('GaodeManagedEventStream cancel is invoked on close', () async {
    final cancelled = Completer<void>();
    setEventChannelHandler(
      onListen: (_, _) {},
      onCancel: cancelled.complete,
    );

    final managed = GaodeManagedEventStream<int>(
      channel: const EventChannel(channelName),
      transform: (event) => event as int,
    );

    managed.stream.listen(null);
    await managed.close();
    await cancelled.future.timeout(const Duration(seconds: 1));
  });
}
