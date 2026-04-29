import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/database/local_database_properties.dart';
import 'package:iamhere/core/database/local_database_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '_helpers/test_database_factory.dart';

void main() {
  setUpAll(TestDatabaseFactory.ensureInitialized);

  group('LocalDatabaseSchema (신규 설치, onCreate)', () {
    late TestDatabaseHandle handle;
    late Database db;

    setUp(() async {
      handle = await TestDatabaseFactory.openCurrentSchema();
      db = handle.database;
    });

    tearDown(() async {
      await handle.dispose();
    });

    test('알려진 모든 테이블이 생성되어야 한다', () async {
      final names = await _tableNames(db);
      expect(
        names,
        containsAll([
          LocalDatabaseProperties.contactTableName,
          LocalDatabaseProperties.geofenceTableName,
          LocalDatabaseProperties.geofenceServerRecipientTableName,
          LocalDatabaseProperties.recordTableName,
          LocalDatabaseProperties.notificationTableName,
        ]),
      );
    });

    test('geofence 테이블에 address 컬럼이 존재한다', () async {
      final cols = await _columnNames(
        db,
        LocalDatabaseProperties.geofenceTableName,
      );
      expect(cols, contains('address'));
    });

    test('notifications 테이블에 sender_nickname / sender_email 컬럼이 존재한다', () async {
      final cols = await _columnNames(
        db,
        LocalDatabaseProperties.notificationTableName,
      );
      expect(cols, containsAll(['sender_nickname', 'sender_email']));
    });

    test('현재 스키마 버전이 LocalDatabaseSchema.version 과 일치해야 한다', () async {
      final result = await db.rawQuery('PRAGMA user_version');
      expect(result.first.values.first, LocalDatabaseSchema.version);
    });
  });

  group('LocalDatabaseSchema (옛 v1 → 최신, onUpgrade)', () {
    test('v1 에 없던 geofence_server_recipient 테이블이 마이그레이션 후 추가된다', () async {
      final handle = await TestDatabaseFactory.openMigratedFromV1();
      addTearDown(handle.dispose);

      final names = await _tableNames(handle.database);
      expect(
        names,
        contains(LocalDatabaseProperties.geofenceServerRecipientTableName),
      );
    });

    test('v1 에 없던 geofence.address 컬럼이 마이그레이션 후 추가된다', () async {
      final handle = await TestDatabaseFactory.openMigratedFromV1();
      addTearDown(handle.dispose);

      final cols = await _columnNames(
        handle.database,
        LocalDatabaseProperties.geofenceTableName,
      );
      expect(cols, contains('address'));
    });

    test('v1 에 없던 notifications sender_* 컬럼이 마이그레이션 후 추가된다', () async {
      final handle = await TestDatabaseFactory.openMigratedFromV1();
      addTearDown(handle.dispose);

      final cols = await _columnNames(
        handle.database,
        LocalDatabaseProperties.notificationTableName,
      );
      expect(cols, containsAll(['sender_nickname', 'sender_email']));
    });

    test('마이그레이션 시 v1 에서 적재된 행은 그대로 보존된다', () async {
      final handle = await TestDatabaseFactory.openMigratedFromV1(
        seed: (v1) async {
          await v1.insert('contacts', {'name': '엄마', 'number': '01012345678'});
          await v1.insert('geofence', {
            'name': '집',
            'lat': 37.0,
            'lng': 127.0,
            'radius': 250.0,
            'message': '도착',
            'contact_ids': '[]',
            'is_active': 0,
          });
        },
      );
      addTearDown(handle.dispose);

      final db = handle.database;
      final contacts = await db.query('contacts');
      final geofences = await db.query('geofence');

      expect(contacts, hasLength(1));
      expect(contacts.first['name'], '엄마');
      expect(geofences, hasLength(1));
      expect(geofences.first['name'], '집');
      // 새로 생긴 컬럼은 기본값 ""
      expect(geofences.first['address'], '');
    });

    test('마이그레이션 후에도 join 쿼리(찾기)가 정상 동작한다', () async {
      final handle = await TestDatabaseFactory.openMigratedFromV1(
        seed: (v1) async {
          await v1.insert('geofence', {
            'name': '집',
            'lat': 37.0,
            'lng': 127.0,
            'radius': 250.0,
            'message': '도착',
            'contact_ids': '[]',
            'is_active': 0,
          });
        },
      );
      addTearDown(handle.dispose);

      final db = handle.database;
      // 운영 코드의 findAll 과 동일한 join 쿼리
      final rows = await db.rawQuery('''
        SELECT g.*,
               (SELECT COUNT(*) FROM geofence_server_recipient r
                WHERE r.geofence_id = g.id) as server_recipient_count
        FROM geofence g
        ORDER BY g.name ASC
      ''');
      expect(rows, hasLength(1));
      expect(rows.first['server_recipient_count'], 0);
    });
  });
}

Future<List<String>> _tableNames(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table'",
  );
  return rows.map((e) => e['name'] as String).toList();
}

Future<List<String>> _columnNames(Database db, String table) async {
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.map((e) => e['name'] as String).toList();
}
