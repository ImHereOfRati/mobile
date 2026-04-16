import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

@module
abstract class LocalDatabaseModule {
  static const String _databaseName = "im_here.db";

  static const String _contactTableName = 'contacts';
  static const String _geofenceTableName = 'geofence';
  static const String _recordTableName = 'records';

  @preResolve
  Future<Database> get database async {
    final path = join(await getDatabasesPath(), _databaseName);

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(_createContactsTableQuery());
        await db.execute(_createGeofenceTableQuery());
        await db.execute(_createRecordsTableQuery());
      },
    );
  }

  String _createContactsTableQuery() =>
      'CREATE TABLE $_contactTableName(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, number TEXT)';

  String _createGeofenceTableQuery() =>
      'CREATE TABLE $_geofenceTableName(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, lat REAL, lng REAL, radius REAL, message TEXT, contact_ids TEXT, is_active INTEGER DEFAULT 0)';

  String _createRecordsTableQuery() =>
      'CREATE TABLE $_recordTableName(id INTEGER PRIMARY KEY AUTOINCREMENT, geofence_id INTEGER, geofence_name TEXT, message TEXT, recipients TEXT, created_at TEXT, send_machine TEXT)';
}
