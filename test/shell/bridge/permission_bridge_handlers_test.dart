import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/shell/bridge/permission_bridge_handlers.dart';

void main() {
  test('requires always-on location for automatic sending', () async {
    final handlers = PermissionBridgeHandlers(
      location: _PermissionService(PermissionState.grantedWhenInUse),
      notification: _PermissionService(PermissionState.grantedAlways),
      batteryOptimization: _PermissionService(PermissionState.grantedAlways),
      contacts: _PermissionService(PermissionState.grantedAlways),
      isLocationServiceEnabled: () async => true,
    ).build();

    expect(await handlers['getAutoSendReadiness']!(null), {
      'ready': false,
      'locationAlways': false,
      'locationService': true,
      'notification': true,
      'batteryOptimization': true,
      'missing': ['locationAlways'],
    });
  });

  test('does not report when-in-use permission as always-on', () async {
    final handlers = PermissionBridgeHandlers(
      location: _PermissionService(PermissionState.grantedWhenInUse),
      notification: _PermissionService(PermissionState.denied),
      batteryOptimization: _PermissionService(PermissionState.denied),
      contacts: _PermissionService(PermissionState.denied),
    ).build();

    expect(
      await handlers['getPermissionStatus']!({'permission': 'locationAlways'}),
      {'permission': 'locationAlways', 'status': 'denied'},
    );
    expect(
      await handlers['getPermissionStatus']!({
        'permission': 'locationWhenInUse',
      }),
      {'permission': 'locationWhenInUse', 'status': 'granted'},
    );
  });
}

class _PermissionService implements PermissionServiceInterface {
  final PermissionState state;

  _PermissionService(this.state);

  @override
  Future<PermissionState> checkPermissionStatus() async => state;

  @override
  Future<bool> isPermissionGranted() async =>
      state == PermissionState.grantedAlways ||
      state == PermissionState.grantedWhenInUse;

  @override
  Future<PermissionState> requestPermission() async => state;
}
