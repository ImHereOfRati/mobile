import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/infrastructure/database/service/notification_database_service.dart';
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
    String alias = '엄마',
    String path = '/record/notifications',
    DateTime? createdAt,
  }) => NotificationEntity(
    title: title,
    body: body,
    senderAlias: alias,
    path: path,
    createdAt: createdAt ?? DateTime(2026, 4, 29, 10),
  );

  test('save → findAll round-trip 시 sender_alias 컬럼이 그대로 복원된다', () async {
    await sut.save(makeEntity(alias: '엄마'));

    final all = await sut.findAll();
    expect(all.single.senderAlias, '엄마');
    expect(all.single.path, '/record/notifications');
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
