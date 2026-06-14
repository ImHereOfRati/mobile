import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/record/model/activity_record_status.dart';
import 'package:iamhere/infrastructure/database/service/record_database_service.dart';
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
        status: ActivityRecordStatus.pending,
        deliveryKey: 'key-$name',
        retryCount: 2,
        lastError: 'temporary network error',
      );

  test('save → findAll round-trip 시 enum/datetime 이 정확히 복원된다', () async {
    await sut.save(makeRecord(machine: SendMachine.server));

    final all = await sut.findAll();
    expect(all, hasLength(1));
    expect(all.single.sendMachine, SendMachine.server);
    expect(all.single.status, ActivityRecordStatus.pending);
    expect(all.single.deliveryKey, 'key-집');
    expect(all.single.retryCount, 2);
    expect(all.single.lastError, 'temporary network error');
    expect(all.single.createdAt, DateTime(2026, 4, 29, 10));
  });

  test('delivery_key 로 저장된 기록을 조회하고 상태를 갱신할 수 있다', () async {
    await sut.save(makeRecord(name: '회사'));

    final found = await sut.findByDeliveryKey('key-회사');
    expect(found, isNotNull);
    expect(found!.status, ActivityRecordStatus.pending);

    await sut.update(
      found.copyWith(
        status: ActivityRecordStatus.completed,
        retryCount: 3,
        lastError: '',
      ),
    );

    final updated = await sut.findByDeliveryKey('key-회사');
    expect(updated, isNotNull);
    expect(updated!.status, ActivityRecordStatus.completed);
    expect(updated.retryCount, 3);
    expect(updated.lastError, '');
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
