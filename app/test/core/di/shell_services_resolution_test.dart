import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/friend/model/service/device_contact_service.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/record/model/service/activity_log_service.dart';
import 'package:iamhere/feature/record/model/service/server_notification_service.dart';

import '../database/_helpers/test_database_factory.dart';

void main() {
  // 추상 타입을 주입받는 서비스는 단위 테스트로 잡히지 않고 앱을 띄울 때 터진다.
  // ShellApp이 시작할 때 꺼내는 서비스가 DI에서 실제로 만들어지는지 확인한다.
  test('resolves the friend and record services the shell needs', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDatabaseFactory.ensureInitialized();
    await enrollBaseUrlGlobally(baseUrl: 'https://example.com');
    addTearDown(getIt.reset);

    expect(getIt<FriendService>(), isA<FriendService>());
    expect(getIt<DeviceContactService>(), isA<DeviceContactService>());
    expect(getIt<ActivityLogService>(), isA<ActivityLogService>());
    expect(
      getIt<ServerNotificationService>(),
      isA<ServerNotificationService>(),
    );
  });
}
