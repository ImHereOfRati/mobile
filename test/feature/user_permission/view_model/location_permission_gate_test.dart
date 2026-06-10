import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/feature/user_permission/view_model/location_permission_gate.dart';

class _FakePermissionService implements PermissionServiceInterface {
  PermissionState current;
  PermissionState afterRequest;
  int requestCount = 0;

  _FakePermissionService({
    required this.current,
    PermissionState? afterRequest,
  }) : afterRequest = afterRequest ?? current;

  @override
  Future<PermissionState> checkPermissionStatus() async => current;

  @override
  Future<PermissionState> requestPermission() async {
    requestCount++;
    current = afterRequest;
    return current;
  }

  @override
  Future<bool> isPermissionGranted() async =>
      current == PermissionState.grantedAlways ||
      current == PermissionState.grantedWhenInUse;
}

void main() {
  group('LocationPermissionGate.resolveForCreate', () {
    test('사용 중 허용이면 요청 없이 true', () async {
      final service =
          _FakePermissionService(current: PermissionState.grantedWhenInUse);
      final gate = LocationPermissionGate(service);

      expect(await gate.resolveForCreate(), isTrue);
      expect(service.requestCount, 0);
    });

    test('항상 허용이면 true', () async {
      final service =
          _FakePermissionService(current: PermissionState.grantedAlways);
      final gate = LocationPermissionGate(service);

      expect(await gate.resolveForCreate(), isTrue);
    });

    test('거부 상태면 1회 요청 후 결과를 따른다', () async {
      final service = _FakePermissionService(
        current: PermissionState.denied,
        afterRequest: PermissionState.grantedWhenInUse,
      );
      final gate = LocationPermissionGate(service);

      expect(await gate.resolveForCreate(), isTrue);
      expect(service.requestCount, 1);
    });

    test('영구 거부면 요청하지 않고 false', () async {
      final service =
          _FakePermissionService(current: PermissionState.permanentlyDenied);
      final gate = LocationPermissionGate(service);

      expect(await gate.resolveForCreate(), isFalse);
      expect(service.requestCount, 0);
    });

    test('요청 후에도 거부면 false', () async {
      final service = _FakePermissionService(
        current: PermissionState.denied,
        afterRequest: PermissionState.denied,
      );
      final gate = LocationPermissionGate(service);

      expect(await gate.resolveForCreate(), isFalse);
    });
  });
}
