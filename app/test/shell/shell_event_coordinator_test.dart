import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/bridge/bridge_event_emitter.dart';
import 'package:iamhere/shell/shell_event_coordinator.dart';

void main() {
  test('resolves FCM type and emits onPushOpened', () async {
    final scripts = <String>[];
    final coordinator = ShellEventCoordinator(
      BridgeEventEmitter((script) async => scripts.add(script)),
    );

    final handled = await coordinator.pushOpened({'type': 'ARRIVAL'});

    expect(handled, isTrue);
    expect(scripts.single, contains('onPushOpened'));
    expect(scripts.single, contains('/record/notifications'));
  });

  test('ignores push data without a valid app path', () async {
    final scripts = <String>[];
    final coordinator = ShellEventCoordinator(
      BridgeEventEmitter((script) async => scripts.add(script)),
    );

    expect(await coordinator.pushOpened({'path': 'https://invalid'}), isFalse);
    expect(scripts, isEmpty);
  });
}
