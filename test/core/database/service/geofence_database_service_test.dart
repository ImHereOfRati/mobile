import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/database/local_database_exception.dart';
import 'package:iamhere/core/database/service/geofence_database_service.dart';
import 'package:iamhere/core/database/service/geofence_server_recipient_database_service.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';

import '../_helpers/test_database_factory.dart';

void main() {
  setUpAll(TestDatabaseFactory.ensureInitialized);

  late TestDatabaseHandle handle;
  late GeofenceDatabaseService sut;
  late GeofenceServerRecipientDatabaseService recipientSut;

  setUp(() async {
    handle = await TestDatabaseFactory.openCurrentSchema();
    sut = GeofenceDatabaseService(handle.database);
    recipientSut = GeofenceServerRecipientDatabaseService(handle.database);
  });

  tearDown(() => handle.dispose());

  GeofenceEntity makeEntity({
    int? id,
    String name = '집',
    String address = '',
    bool isActive = false,
  }) =>
      GeofenceEntity(
        id: id,
        name: name,
        address: address,
        lat: 37.0,
        lng: 127.0,
        radius: 250.0,
        message: '도착',
        contactIds: '[]',
        isActive: isActive,
      );

  group('save', () {
    test('새 엔티티를 저장하면 자동 부여된 id 가 반환된다', () async {
      final saved = await sut.save(makeEntity(name: '집'));

      expect(saved.id, isNotNull);
      expect(saved.name, '집');
    });

    test('연속 저장 시 id 가 단조 증가한다', () async {
      final a = await sut.save(makeEntity(name: '집'));
      final b = await sut.save(makeEntity(name: '회사'));

      expect(b.id, greaterThan(a.id!));
    });
  });

  group('findAll', () {
    test('빈 DB 에서는 빈 리스트를 돌려준다', () async {
      final result = await sut.findAll();
      expect(result, isEmpty);
    });

    test('이름 오름차순으로 정렬되어 반환된다', () async {
      await sut.save(makeEntity(name: '회사'));
      await sut.save(makeEntity(name: '집'));
      await sut.save(makeEntity(name: '학교'));

      final names = (await sut.findAll()).map((g) => g.name).toList();
      expect(names, ['집', '학교', '회사']); // ㅈ < ㅎ < ㅎ → utf-16 기준
    });

    test('server_recipient_count 는 연결된 server recipient 수와 일치한다', () async {
      final saved = await sut.save(makeEntity(name: '집'));
      await recipientSut.save(GeofenceServerRecipientEntity(
        geofenceId: saved.id!,
        friendRelationshipId: 'rel-1',
        friendEmail: 'a@example.com',
      ));
      await recipientSut.save(GeofenceServerRecipientEntity(
        geofenceId: saved.id!,
        friendRelationshipId: 'rel-2',
        friendEmail: 'b@example.com',
      ));

      final list = await sut.findAll();
      final target = list.firstWhere((g) => g.id == saved.id);
      expect(target.serverRecipientCount, 2);
    });

    test('연결된 recipient 가 없으면 server_recipient_count 는 0', () async {
      await sut.save(makeEntity(name: '집'));

      final list = await sut.findAll();
      expect(list.single.serverRecipientCount, 0);
    });
  });

  group('update', () {
    test('값이 갱신되어 findAll 에 반영된다', () async {
      final saved = await sut.save(makeEntity(name: '집', address: ''));

      await sut.update(saved.copyWith(address: '서울시 강남구'));

      final list = await sut.findAll();
      expect(list.single.address, '서울시 강남구');
    });

    test('id 가 null 이면 LocalDatabaseException 을 던진다', () async {
      expect(
        () => sut.update(makeEntity(name: '집')),
        throwsA(isA<LocalDatabaseException>()),
      );
    });
  });

  group('updateActiveStatus / updateAddress', () {
    test('updateActiveStatus 는 is_active 만 바꾼다', () async {
      final saved = await sut.save(makeEntity(name: '집'));
      await sut.updateActiveStatus(saved.id!, true);

      final list = await sut.findAll();
      expect(list.single.isActive, isTrue);
      expect(list.single.name, '집'); // 다른 컬럼은 그대로
    });

    test('updateAddress 는 address 만 바꾼다', () async {
      final saved = await sut.save(makeEntity(name: '집'));
      await sut.updateAddress(saved.id!, '경기도 분당');

      final list = await sut.findAll();
      expect(list.single.address, '경기도 분당');
    });
  });

  group('delete', () {
    test('해당 id 의 행을 제거하고, 연결된 server recipient 도 CASCADE 로 사라진다', () async {
      final saved = await sut.save(makeEntity(name: '집'));
      await recipientSut.save(GeofenceServerRecipientEntity(
        geofenceId: saved.id!,
        friendRelationshipId: 'rel-1',
        friendEmail: 'a@example.com',
      ));

      await sut.delete(saved.id!);

      expect(await sut.findAll(), isEmpty);
      expect(await recipientSut.findByGeofenceId(saved.id!), isEmpty);
    });
  });
}
