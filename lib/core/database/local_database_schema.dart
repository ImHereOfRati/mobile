import 'package:sqflite/sqflite.dart';

import 'local_database_properties.dart';

/// 로컬 SQLite 의 단일 진실 공급원.
///
/// 운영 환경의 [openDatabase] 호출과 테스트의 in-memory 인스턴스가 동일한
/// 스키마/마이그레이션 로직을 공유하도록 한 곳에 모았다.
///
/// 변경 시 체크리스트:
///   1. [version] 을 올린다.
///   2. [onCreate] 에 신규 컬럼/테이블을 반영한다 (신규 설치 경로).
///   3. [onUpgrade] 에 (oldVersion < N) 분기를 추가해 기존 사용자 DB 를 보정.
///
/// ALTER 가 실패해도 앱이 죽지 않도록 [_safeExec] 로 감싼다 — 같은 컬럼/테이블이
/// 이미 있어도 진행할 수 있게 만들기 위함이다.
class LocalDatabaseSchema {
  LocalDatabaseSchema._();

  /// 스키마 변경마다 1씩 증가시킨다.
  /// v1: 초기 (contacts, geofence, records, notifications)
  /// v2: geofence.address, geofence_server_recipient, notifications.sender_*
  static const int version = 2;

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> onCreate(Database db, int version) async {
    await db.execute(_createContactsTable);
    await db.execute(_createGeofenceTable);
    await db.execute(_createGeofenceServerRecipientTable);
    await db.execute(_createRecordsTable);
    await db.execute(_createNotificationsTable);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
  }

  static Future<void> _migrateToV2(Database db) async {
    // v1 → v2: 누락된 컬럼/테이블 보정.
    await _safeExec(
      db,
      'ALTER TABLE ${LocalDatabaseProperties.geofenceTableName} '
      'ADD COLUMN address TEXT DEFAULT ""',
    );
    await _safeExec(db, _createGeofenceServerRecipientTable);
    await _safeExec(
      db,
      'ALTER TABLE ${LocalDatabaseProperties.notificationTableName} '
      'ADD COLUMN sender_nickname TEXT DEFAULT ""',
    );
    await _safeExec(
      db,
      'ALTER TABLE ${LocalDatabaseProperties.notificationTableName} '
      'ADD COLUMN sender_email TEXT DEFAULT ""',
    );
  }

  /// onUpgrade 가 부분 실행된 적이 있는 기기 등에서 같은 마이그레이션을
  /// 다시 시도해도 앱을 죽이지 않도록 한다.
  static Future<void> _safeExec(Database db, String sql) async {
    try {
      await db.execute(sql);
    } on DatabaseException catch (e) {
      if (e.isDuplicateColumnError() || _isAlreadyExists(e)) return;
      rethrow;
    }
  }

  static bool _isAlreadyExists(DatabaseException e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('already exists');
  }

  static const String _createContactsTable =
      'CREATE TABLE ${LocalDatabaseProperties.contactTableName}'
      '(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, number TEXT)';

  static const String _createGeofenceTable =
      'CREATE TABLE ${LocalDatabaseProperties.geofenceTableName}'
      '(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name TEXT, '
      'address TEXT DEFAULT "", '
      'lat REAL, '
      'lng REAL, '
      'radius REAL, '
      'message TEXT, '
      'contact_ids TEXT, '
      'is_active INTEGER DEFAULT 0)';

  static const String _createGeofenceServerRecipientTable =
      'CREATE TABLE IF NOT EXISTS '
      '${LocalDatabaseProperties.geofenceServerRecipientTableName}'
      '(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'geofence_id INTEGER NOT NULL, '
      'friend_relationship_id TEXT NOT NULL, '
      'friend_email TEXT NOT NULL, '
      'friend_alias TEXT NOT NULL DEFAULT "", '
      'FOREIGN KEY (geofence_id) REFERENCES '
      '${LocalDatabaseProperties.geofenceTableName}(id) ON DELETE CASCADE)';

  static const String _createRecordsTable =
      'CREATE TABLE ${LocalDatabaseProperties.recordTableName}'
      '(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'geofence_id INTEGER, '
      'geofence_name TEXT, '
      'message TEXT, '
      'recipients TEXT, '
      'created_at TEXT, '
      'send_machine TEXT)';

  static const String _createNotificationsTable =
      'CREATE TABLE ${LocalDatabaseProperties.notificationTableName}'
      '(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'title TEXT, '
      'body TEXT, '
      'sender_nickname TEXT DEFAULT "", '
      'sender_email TEXT DEFAULT "", '
      'created_at TEXT)';
}
