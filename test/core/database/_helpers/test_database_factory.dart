import 'dart:io';

import 'package:iamhere/core/database/local_database_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 테스트용 SQLite 인스턴스 빌더.
///
/// in-memory 는 connection 마다 격리되어 reopen 시나리오에서 상태가
/// 사라지므로, 마이그레이션 검증을 위해 임시 파일 경로를 사용한다.
/// 각 호출은 새 임시 파일을 만들고 [TestDatabaseHandle.dispose] 에서 정리한다.
class TestDatabaseFactory {
  TestDatabaseFactory._();

  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _initialized = true;
  }

  static Future<TestDatabaseHandle> openCurrentSchema() async {
    ensureInitialized();
    final path = await _allocatePath();
    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: LocalDatabaseSchema.version,
        onConfigure: LocalDatabaseSchema.onConfigure,
        onCreate: LocalDatabaseSchema.onCreate,
        onUpgrade: LocalDatabaseSchema.onUpgrade,
      ),
    );
    return TestDatabaseHandle._(db, path);
  }

  /// 옛 v1 스키마(`address` 컬럼 / `geofence_server_recipient` 테이블 /
  /// `notifications.sender_*` 컬럼 없음)로 열어 두고, 시드한 뒤 닫고,
  /// 최신 version 으로 다시 열어 onUpgrade 를 실제로 거치게 한다.
  static Future<TestDatabaseHandle> openMigratedFromV1({
    Future<void> Function(Database v1Db)? seed,
  }) async {
    ensureInitialized();
    final path = await _allocatePath();

    final v1 = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: LocalDatabaseSchema.onConfigure,
        onCreate: _legacyV1OnCreate,
      ),
    );
    if (seed != null) {
      await seed(v1);
    }
    await v1.close();

    final db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: LocalDatabaseSchema.version,
        onConfigure: LocalDatabaseSchema.onConfigure,
        onCreate: LocalDatabaseSchema.onCreate,
        onUpgrade: LocalDatabaseSchema.onUpgrade,
      ),
    );
    return TestDatabaseHandle._(db, path);
  }

  static Future<void> _legacyV1OnCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE contacts(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name TEXT, number TEXT)',
    );
    await db.execute(
      'CREATE TABLE geofence(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'name TEXT, lat REAL, lng REAL, radius REAL, message TEXT, '
      'contact_ids TEXT, is_active INTEGER DEFAULT 0)',
    );
    await db.execute(
      'CREATE TABLE records(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'geofence_id INTEGER, geofence_name TEXT, message TEXT, '
      'recipients TEXT, created_at TEXT, send_machine TEXT)',
    );
    await db.execute(
      'CREATE TABLE notifications(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'title TEXT, body TEXT, created_at TEXT)',
    );
  }

  static int _counter = 0;
  static Future<String> _allocatePath() async {
    final dir = await Directory.systemTemp.createTemp('imhere_db_test_');
    final id = _counter++;
    return '${dir.path}${Platform.pathSeparator}test_$id.db';
  }
}

class TestDatabaseHandle {
  TestDatabaseHandle._(this.database, this._path);

  final Database database;
  final String _path;

  Future<void> dispose() async {
    if (database.isOpen) {
      await database.close();
    }
    final file = File(_path);
    if (await file.exists()) {
      await file.delete();
    }
    final dir = Directory(File(_path).parent.path);
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  }
}
