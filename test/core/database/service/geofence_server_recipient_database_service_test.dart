import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/database/service/geofence_database_service.dart';
import 'package:iamhere/core/database/service/geofence_server_recipient_database_service.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/repository/geofence_server_recipient_entity.dart';

import '../_helpers/test_database_factory.dart';

void main() {
  setUpAll(TestDatabaseFactory.ensureInitialized);

  late TestDatabaseHandle handle;
  late GeofenceDatabaseService geofenceSut;
  late GeofenceServerRecipientDatabaseService sut;
  late int geofenceId;

  setUp(() async {
    handle = await TestDatabaseFactory.openCurrentSchema();
    geofenceSut = GeofenceDatabaseService(handle.database);
    sut = GeofenceServerRecipientDatabaseService(handle.database);

    final saved = await geofenceSut.save(GeofenceEntity(
      name: '집',
      lat: 37.0,
      lng: 127.0,
      radius: 250.0,
      message: '도착',
      contactIds: '[]',
    ));
    geofenceId = saved.id!;
  });

  tearDown(() => handle.dispose());

  GeofenceServerRecipientEntity makeEntity({
    String relId = 'rel-1',
    String email = 'a@example.com',
    String alias = '엄마',
  }) =>
      GeofenceServerRecipientEntity(
        geofenceId: geofenceId,
        friendRelationshipId: relId,
        friendEmail: email,
        friendAlias: alias,
      );

  test('save 후 id 가 부여되고 findByGeofenceId 로 조회된다', () async {
    final saved = await sut.save(makeEntity());

    expect(saved.id, isNotNull);
    final found = await sut.findByGeofenceId(geofenceId);
    expect(found, hasLength(1));
    expect(found.single.friendEmail, 'a@example.com');
    expect(found.single.friendAlias, '엄마');
  });

  test('다른 geofence_id 에 속한 recipient 는 findByGeofenceId 결과에서 빠진다', () async {
    final other = await geofenceSut.save(GeofenceEntity(
      name: '회사',
      lat: 37.0,
      lng: 127.0,
      radius: 250.0,
      message: '도착',
      contactIds: '[]',
    ));
    await sut.save(makeEntity(relId: 'home'));
    await sut.save(GeofenceServerRecipientEntity(
      geofenceId: other.id!,
      friendRelationshipId: 'work',
      friendEmail: 'c@example.com',
    ));

    final result = await sut.findByGeofenceId(geofenceId);
    expect(result, hasLength(1));
    expect(result.single.friendRelationshipId, 'home');
  });

  test('deleteByGeofenceId 는 해당 geofence 의 recipient 만 제거한다', () async {
    final other = await geofenceSut.save(GeofenceEntity(
      name: '회사',
      lat: 37.0,
      lng: 127.0,
      radius: 250.0,
      message: '도착',
      contactIds: '[]',
    ));
    await sut.save(makeEntity(relId: 'home'));
    await sut.save(GeofenceServerRecipientEntity(
      geofenceId: other.id!,
      friendRelationshipId: 'work',
      friendEmail: 'c@example.com',
    ));

    await sut.deleteByGeofenceId(geofenceId);

    expect(await sut.findByGeofenceId(geofenceId), isEmpty);
    expect(await sut.findByGeofenceId(other.id!), hasLength(1));
  });

  test('부모 geofence 삭제 시 ON DELETE CASCADE 가 동작한다', () async {
    await sut.save(makeEntity());
    expect(await sut.findByGeofenceId(geofenceId), hasLength(1));

    await geofenceSut.delete(geofenceId);

    expect(await sut.findByGeofenceId(geofenceId), isEmpty);
  });
}
