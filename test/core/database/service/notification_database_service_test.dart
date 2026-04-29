import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/database/service/notification_database_service.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';

import '../_helpers/test_database_factory.dart';

void main() {
  setUpAll(TestDatabaseFactory.ensureInitialized);

  late TestDatabaseHandle handle;
  late NotificationDatabaseService sut;

  setUp(() async {
    handle = await TestDatabaseFactory.openCurrentSchema();
    sut = NotificationDatabaseService(handle.database);
  });

  tearDown(() => handle.dispose());

  NotificationEntity makeEntity({
    String title = '알림',
    String body = '메시지',
    String nickname = '엄마',
    String email = 'a@example.com',
    DateTime? createdAt,
  }) =>
      NotificationEntity(
        title: title,
        body: body,
        senderNickname: nickname,
        senderEmail: email,
        createdAt: createdAt ?? DateTime(2026, 4, 29, 10),
      );

  test('save → findAll round-trip 시 sender_* 컬럼이 그대로 복원된다', () async {
    await sut.save(makeEntity(nickname: '엄마', email: 'mom@example.com'));

    final all = await sut.findAll();
    expect(all.single.senderNickname, '엄마');
    expect(all.single.senderEmail, 'mom@example.com');
  });

  test('findAll 은 created_at 내림차순(최신부터) 으로 반환한다', () async {
    await sut.save(makeEntity(title: '옛것', createdAt: DateTime(2026, 1, 1)));
    await sut.save(makeEntity(title: '최신', createdAt: DateTime(2026, 4, 28)));

    final titles = (await sut.findAll()).map((e) => e.title).toList();
    expect(titles, ['최신', '옛것']);
  });

  test('deleteAll 은 모든 행을 비운다', () async {
    await sut.save(makeEntity());
    await sut.save(makeEntity());

    await sut.deleteAll();

    expect(await sut.findAll(), isEmpty);
  });
}
