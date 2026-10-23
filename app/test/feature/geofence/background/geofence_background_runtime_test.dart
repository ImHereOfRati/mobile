import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/background/geofence_background_runtime.dart';

void main() {
  test('동시 initialize 호출은 같은 in-flight 초기화를 공유한다', () async {
    final firebaseGate = Completer<void>();
    var flutterCalls = 0;
    var pluginCalls = 0;
    var firebaseCalls = 0;
    var baseUrlCalls = 0;

    final runtime = GeofenceBackgroundRuntime(
      initializeFlutter: () {
        flutterCalls++;
      },
      registerPlugins: () {
        pluginCalls++;
      },
      initializeFirebaseIfNeeded: () {
        firebaseCalls++;
        return firebaseGate.future;
      },
      enrollBaseUrlIfNeeded: () {
        baseUrlCalls++;
      },
    );

    final first = runtime.initialize();
    final second = runtime.initialize();

    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);

    expect(flutterCalls, 1);
    expect(pluginCalls, 1);
    expect(firebaseCalls, 1);
    expect(baseUrlCalls, 0);

    firebaseGate.complete();
    await Future.wait([first, second]);

    expect(baseUrlCalls, 1);
  });

  test('성공 후 initialize 재호출은 외부 초기화를 반복하지 않는다', () async {
    var calls = 0;
    final runtime = GeofenceBackgroundRuntime(
      initializeFlutter: () => calls++,
      registerPlugins: () => calls++,
      initializeFirebaseIfNeeded: () => calls++,
      enrollBaseUrlIfNeeded: () => calls++,
    );

    await runtime.initialize();
    await runtime.initialize();

    expect(calls, 4);
  });

  test('초기화 실패 후 다음 호출에서 다시 시도한다', () async {
    var firebaseCalls = 0;
    var baseUrlCalls = 0;
    final runtime = GeofenceBackgroundRuntime(
      initializeFlutter: () {},
      registerPlugins: () {},
      initializeFirebaseIfNeeded: () {
        firebaseCalls++;
        if (firebaseCalls == 1) {
          throw StateError('firebase failed');
        }
      },
      enrollBaseUrlIfNeeded: () {
        baseUrlCalls++;
      },
    );

    await expectLater(runtime.initialize(), throwsStateError);

    await runtime.initialize();

    expect(firebaseCalls, 2);
    expect(baseUrlCalls, 1);
  });
}
