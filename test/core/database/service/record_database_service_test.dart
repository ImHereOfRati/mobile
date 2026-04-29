import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/database/service/record_database_service.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';

import '../_helpers/test_database_factory.dart';

void main() {
  setUpAll(TestDatabaseFactory.ensureInitialized);

  late TestDatabaseHandle handle;
  late RecordDatabaseService sut;

  setUp(() async {
    handle = await TestDatabaseFactory.openCurrentSchema();
    sut = RecordDatabaseService(handle.database);
  });

  tearDown(() => handle.dispose());

  GeofenceRecordEntity makeRecord({
    String name = '집',
    DateTime? createdAt,
    SendMachine machine = SendMachine.mobile,
  }) =>
      GeofenceRecordEntity(
        geofenceId: 1,
        geofenceName: name,
        message: '도착',
        recipients: '["a@example.com"]',
        createdAt: createdAt ?? DateTime(2026, 4, 29, 10),
        sendMachine: machine,
      );

  test('save → findAll round-trip 시 enum/datetime 이 정확히 복원된다', () async {
    await sut.save(makeRecord(machine: SendMachine.server));

    final all = await sut.findAll();
    expect(all, hasLength(1));
    expect(all.single.sendMachine, SendMachine.server);
    expect(all.single.createdAt, DateTime(2026, 4, 29, 10));
  });

  test('findAll 은 created_at 내림차순(최신부터) 으로 반환한다', () async {
    await sut.save(makeRecord(name: '오래됨', createdAt: DateTime(2026, 1, 1)));
    await sut.save(makeRecord(name: '최신', createdAt: DateTime(2026, 4, 28)));
    await sut.save(makeRecord(name: '중간', createdAt: DateTime(2026, 3, 15)));

    final names = (await sut.findAll()).map((e) => e.geofenceName).toList();
    expect(names, ['최신', '중간', '오래됨']);
  });

  test('deleteAll 은 모든 행을 비운다', () async {
    await sut.save(makeRecord());
    await sut.save(makeRecord());
    expect(await sut.findAll(), hasLength(2));

    await sut.deleteAll();

    expect(await sut.findAll(), isEmpty);
  });
}
