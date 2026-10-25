import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/user_permission/service/permission_onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a fresh install has not finished the permission guide', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const service = PermissionOnboardingService(FlutterSecureStorage());

    expect(await service.isCompleted(), isFalse);
  });

  test('remembers that the guide was finished', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const service = PermissionOnboardingService(FlutterSecureStorage());

    await service.markCompleted();

    expect(await service.isCompleted(), isTrue);
  });
}
