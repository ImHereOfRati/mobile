import 'package:iamhere/core/database/local_database_properties.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

@module
abstract class LocalDatabaseModule {
  @preResolve
  Future<Database> get database async {
    final path = join(
      await getDatabasesPath(),
      LocalDatabaseProperties.databaseName,
    );

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(_createContactsTableQuery());
        await db.execute(_createGeofenceTableQuery());
        await db.execute(_createRecordsTableQuery());
        await db.execute(_createNotificationsTableQuery());
      },
    );
  }

  String _createContactsTableQuery() =>
      'CREATE TABLE ${LocalDatabaseProperties.contactTableName}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, number TEXT)';

  String _createGeofenceTableQuery() =>
      'CREATE TABLE ${LocalDatabaseProperties.geofenceTableName}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, address TEXT DEFAULT "", lat REAL, lng REAL, radius REAL, message TEXT, contact_ids TEXT, is_active INTEGER DEFAULT 0)';

  String _createRecordsTableQuery() =>
      'CREATE TABLE ${LocalDatabaseProperties.recordTableName}(id INTEGER PRIMARY KEY AUTOINCREMENT, geofence_id INTEGER, geofence_name TEXT, message TEXT, recipients TEXT, created_at TEXT, send_machine TEXT)';

  String _createNotificationsTableQuery() =>
      'CREATE TABLE ${LocalDatabaseProperties.notificationTableName}(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, body TEXT, sender_nickname TEXT DEFAULT "", sender_email TEXT DEFAULT "", created_at TEXT)';
}
