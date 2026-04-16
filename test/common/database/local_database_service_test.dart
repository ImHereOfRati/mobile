import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/friend/repository/contact_entity.dart';
import 'package:iamhere/geofence/repository/geofence_entity.dart';
import 'package:iamhere/record/repository/geofence_record_entity.dart';
import 'package:iamhere/shared/infrastructure/database/local_database_exception.dart';
import 'package:iamhere/shared/infrastructure/database/local_database_properties.dart';
import 'package:iamhere/shared/infrastructure/database/local_database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('LocalDatabaseService Tests', () {
    late Database database;
    late LocalDatabaseService dbService;

    setUp(() async {
      // Create in-memory database
      database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            // Create contacts table
            await db.execute(
              'CREATE TABLE ${LocalDatabaseProperties.contactTableName}('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'name TEXT, '
              'number TEXT)',
            );

            // Create geofence table
            await db.execute(
              'CREATE TABLE ${LocalDatabaseProperties.geofenceTableName}('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'name TEXT, '
              'lat REAL, '
              'lng REAL, '
              'radius REAL, '
              'message TEXT, '
              'contact_ids TEXT, '
              'is_active INTEGER DEFAULT 0)',
            );

            // Create records table
            await db.execute(
              'CREATE TABLE ${LocalDatabaseProperties.recordTableName}('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'geofence_id INTEGER, '
              'geofence_name TEXT, '
              'message TEXT, '
              'recipients TEXT, '
              'created_at TEXT, '
              'send_machine TEXT)',
            );
          },
        ),
      );

      dbService = LocalDatabaseService(database);
    });

    tearDown(() async {
      await database.close();
    });

    group('Contact Operations', () {
      test('should save and retrieve a friend', () async {
        final contact = ContactEntity(name: 'John', number: '010-1234-5678');
        final saved = await dbService.saveContact(contact);

        expect(saved.id, isNotNull);
        expect(saved.name, 'John');
        expect(saved.number, '010-1234-5678');

        final all = await dbService.findAllContacts();
        expect(all.length, 1);
        expect(all[0].id, saved.id);
        expect(all[0].name, 'John');
      });

      test('should find contacts ordered by name', () async {
        await dbService.saveContact(
          ContactEntity(name: 'Charlie', number: '333'),
        );
        await dbService.saveContact(
          ContactEntity(name: 'Alice', number: '111'),
        );
        await dbService.saveContact(ContactEntity(name: 'Bob', number: '222'));

        final all = await dbService.findAllContacts();
        expect(all.length, 3);
        expect(all[0].name, 'Alice');
        expect(all[1].name, 'Bob');
        expect(all[2].name, 'Charlie');
      });

      test('should update an existing friend', () async {
        final contact = await dbService.saveContact(
          ContactEntity(name: 'John', number: '111'),
        );

        final updated = contact.copyWith(name: 'Jane', number: '222');
        final count = await dbService.updateContact(updated);

        expect(count, 1);

        final all = await dbService.findAllContacts();
        expect(all[0].name, 'Jane');
        expect(all[0].number, '222');
      });

      test(
        'should throw LocalDatabaseException when updating friend without ID',
        () async {
          final contact = ContactEntity(name: 'John', number: '111');

          expect(
            () => dbService.updateContact(contact),
            throwsA(isA<LocalDatabaseException>()),
          );
        },
      );

      test(
        'should throw LocalDatabaseException when updating non-existent friend',
        () async {
          final contact = ContactEntity(id: 9999, name: 'John', number: '111');

          expect(
            () => dbService.updateContact(contact),
            throwsA(isA<LocalDatabaseException>()),
          );
        },
      );

      test('should delete a friend', () async {
        final contact = await dbService.saveContact(
          ContactEntity(name: 'John', number: '111'),
        );

        await dbService.deleteContact(contact.id!);

        final all = await dbService.findAllContacts();
        expect(all.isEmpty, true);
      });
    });

    group('Geofence Operations', () {
      test('should save and retrieve a geofence', () async {
        final geofence = GeofenceEntity(
          name: 'Home',
          lat: 37.123,
          lng: 127.456,
          radius: 100.0,
          message: 'Test',
          contactIds: '[]',
        );

        final saved = await dbService.saveGeofence(geofence);
        expect(saved.id, isNotNull);
        expect(saved.name, 'Home');
        expect(saved.isActive, false);

        final all = await dbService.findAllGeofences();
        expect(all.length, 1);
        expect(all[0].name, 'Home');
      });

      test('should find geofences ordered by name', () async {
        await dbService.saveGeofence(
          GeofenceEntity(
            name: 'Zoo',
            lat: 1.0,
            lng: 1.0,
            radius: 100.0,
            message: '',
            contactIds: '[]',
          ),
        );
        await dbService.saveGeofence(
          GeofenceEntity(
            name: 'Alpha',
            lat: 2.0,
            lng: 2.0,
            radius: 100.0,
            message: '',
            contactIds: '[]',
          ),
        );

        final all = await dbService.findAllGeofences();
        expect(all.length, 2);
        expect(all[0].name, 'Alpha');
        expect(all[1].name, 'Zoo');
      });

      test('should update an existing geofence', () async {
        final geofence = await dbService.saveGeofence(
          GeofenceEntity(
            name: 'Home',
            lat: 37.123,
            lng: 127.456,
            radius: 100.0,
            message: 'Old',
            contactIds: '[]',
          ),
        );

        final updated = geofence.copyWith(message: 'New', radius: 200.0);
        final count = await dbService.updateGeofence(updated);

        expect(count, 1);

        final all = await dbService.findAllGeofences();
        expect(all[0].message, 'New');
        expect(all[0].radius, 200.0);
      });

      test('should update geofence active status', () async {
        final geofence = await dbService.saveGeofence(
          GeofenceEntity(
            name: 'Home',
            lat: 37.123,
            lng: 127.456,
            radius: 100.0,
            message: '',
            contactIds: '[]',
          ),
        );

        await dbService.updateGeofenceActiveStatus(geofence.id!, true);

        final all = await dbService.findAllGeofences();
        expect(all[0].isActive, true);
      });

      test('should delete a geofence', () async {
        final geofence = await dbService.saveGeofence(
          GeofenceEntity(
            name: 'Home',
            lat: 37.123,
            lng: 127.456,
            radius: 100.0,
            message: '',
            contactIds: '[]',
          ),
        );

        await dbService.deleteGeofence(geofence.id!);

        final all = await dbService.findAllGeofences();
        expect(all.isEmpty, true);
      });
    });

    group('GeofenceRecord Operations', () {
      test('should save and retrieve a record', () async {
        final record = GeofenceRecordEntity(
          geofenceId: 1,
          geofenceName: 'Home',
          message: 'Test message',
          recipients: '["John"]',
          createdAt: DateTime.now(),
          sendMachine: SendMachine.mobile,
        );

        final saved = await dbService.saveGeofenceRecord(record);
        expect(saved.id, isNotNull);
        expect(saved.geofenceName, 'Home');

        final all = await dbService.findAllGeofenceRecords();
        expect(all.length, 1);
        expect(all[0].message, 'Test message');
      });

      test('should find records ordered by created_at DESC', () async {
        final now = DateTime.now();

        await dbService.saveGeofenceRecord(
          GeofenceRecordEntity(
            geofenceId: 1,
            geofenceName: 'Home',
            message: 'First',
            recipients: '[]',
            createdAt: now.subtract(const Duration(hours: 2)),
            sendMachine: SendMachine.mobile,
          ),
        );

        await dbService.saveGeofenceRecord(
          GeofenceRecordEntity(
            geofenceId: 1,
            geofenceName: 'Home',
            message: 'Second',
            recipients: '[]',
            createdAt: now.subtract(const Duration(hours: 1)),
            sendMachine: SendMachine.mobile,
          ),
        );

        await dbService.saveGeofenceRecord(
          GeofenceRecordEntity(
            geofenceId: 1,
            geofenceName: 'Home',
            message: 'Third',
            recipients: '[]',
            createdAt: now,
            sendMachine: SendMachine.mobile,
          ),
        );

        final all = await dbService.findAllGeofenceRecords();
        expect(all.length, 3);
        expect(all[0].message, 'Third'); // Most recent first
        expect(all[1].message, 'Second');
        expect(all[2].message, 'First');
      });

      test('should update an existing record', () async {
        final record = await dbService.saveGeofenceRecord(
          GeofenceRecordEntity(
            geofenceId: 1,
            geofenceName: 'Home',
            message: 'Old',
            recipients: '[]',
            createdAt: DateTime.now(),
            sendMachine: SendMachine.mobile,
          ),
        );

        final updated = record.copyWith(
          message: 'New',
          sendMachine: SendMachine.server,
        );
        final count = await dbService.updateGeofenceRecord(updated);

        expect(count, 1);

        final all = await dbService.findAllGeofenceRecords();
        expect(all[0].message, 'New');
        expect(all[0].sendMachine, SendMachine.server);
      });

      test('should delete a record', () async {
        final record = await dbService.saveGeofenceRecord(
          GeofenceRecordEntity(
            geofenceId: 1,
            geofenceName: 'Home',
            message: 'Test',
            recipients: '[]',
            createdAt: DateTime.now(),
            sendMachine: SendMachine.mobile,
          ),
        );

        await dbService.deleteGeofenceRecord(record.id!);

        final all = await dbService.findAllGeofenceRecords();
        expect(all.isEmpty, true);
      });

      test('should delete all records', () async {
        await dbService.saveGeofenceRecord(
          GeofenceRecordEntity(
            geofenceId: 1,
            geofenceName: 'Home',
            message: 'First',
            recipients: '[]',
            createdAt: DateTime.now(),
            sendMachine: SendMachine.mobile,
          ),
        );

        await dbService.saveGeofenceRecord(
          GeofenceRecordEntity(
            geofenceId: 1,
            geofenceName: 'Home',
            message: 'Second',
            recipients: '[]',
            createdAt: DateTime.now(),
            sendMachine: SendMachine.mobile,
          ),
        );

        await dbService.deleteAllGeofenceRecords();

        final all = await dbService.findAllGeofenceRecords();
        expect(all.isEmpty, true);
      });
    });
  });
}
