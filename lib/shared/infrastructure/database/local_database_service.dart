import 'package:iamhere/contact/repository/contact_entity.dart';
import 'package:iamhere/geofence/repository/geofence_entity.dart';
import 'package:iamhere/record/repository/geofence_record_entity.dart';
import 'package:iamhere/shared/infrastructure/database/local_database_exception.dart';
import 'package:iamhere/shared/infrastructure/database/local_database_properties.dart';
import 'package:injectable/injectable.dart';
import 'package:sqflite/sqflite.dart';

@singleton
class LocalDatabaseService {
  final Database _db;
  LocalDatabaseService(this._db);

  Future<T> _executeInsert<T>({
    required String entityName,
    required String table,
    required Map<String, dynamic> values,
    required T Function(int id) createEntity,
    String? entityDetails,
  }) async {
    try {
      // _db 사용
      final id = await _db.insert(
        table,
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return createEntity(id);
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to save $entityName',
        details: entityDetails,
        originalError: e,
      );
    }
  }

  Future<int> _executeUpdate({
    required String entityName,
    required int? entityId,
    required String table,
    required Map<String, dynamic> values,
    String? entityDetails,
  }) async {
    if (entityId == null) {
      throw LocalDatabaseException(
        'Cannot update $entityName without ID',
        details: entityDetails,
      );
    }

    try {
      // _db 사용
      final count = await _db.update(
        table,
        values,
        where: 'id = ?',
        whereArgs: [entityId],
      );

      if (count == 0) {
        throw LocalDatabaseException(
          '$entityName not found',
          details: 'ID: $entityId',
        );
      }

      return count;
    } catch (e) {
      if (e is LocalDatabaseException) rethrow;
      throw LocalDatabaseException(
        'Failed to update $entityName',
        details: entityDetails ?? 'ID: $entityId',
        originalError: e,
      );
    }
  }

  Future<List<T>> _executeQuery<T>({
    required String entityName,
    required String table,
    required T Function(Map<String, dynamic>) fromMap,
    String? orderBy,
  }) async {
    try {
      // _db 사용
      final result = await _db.query(table, orderBy: orderBy);
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to fetch ${entityName}s',
        originalError: e,
      );
    }
  }

  Future<void> _executeDelete({
    required String entityName,
    required String table,
    int? id,
    String? additionalDetails,
  }) async {
    try {
      // _db 사용
      if (id != null) {
        await _db.delete(table, where: 'id = ?', whereArgs: [id]);
      } else {
        await _db.delete(table);
      }
    } catch (e) {
      final details = id != null ? 'ID: $id' : additionalDetails;
      throw LocalDatabaseException(
        'Failed to delete $entityName',
        details: details,
        originalError: e,
      );
    }
  }

  // ========== Contact Operations ==========
  // 기존 로직과 동일하지만 내부적으로 깔끔해진 _execute 메서드들을 사용합니다.

  Future<ContactEntity> saveContact(ContactEntity entity) async {
    return await _executeInsert(
      entityName: 'contact',
      table: LocalDatabaseProperties.contactTableName,
      values: entity.toMap(),
      createEntity: (id) => entity.copyWith(id: id),
      entityDetails: 'Contact: ${entity.name}',
    );
  }

  Future<int> updateContact(ContactEntity entity) async {
    return await _executeUpdate(
      entityName: 'Contact',
      entityId: entity.id,
      table: LocalDatabaseProperties.contactTableName,
      values: entity.toMap(),
      entityDetails: 'Contact: ${entity.name}',
    );
  }

  Future<List<ContactEntity>> findAllContacts() async {
    return await _executeQuery(
      entityName: 'contact',
      table: LocalDatabaseProperties.contactTableName,
      fromMap: ContactEntity.fromMap,
      orderBy: 'name ASC',
    );
  }

  Future<void> deleteContact(int id) async {
    return await _executeDelete(
      entityName: 'contact',
      table: LocalDatabaseProperties.contactTableName,
      id: id,
    );
  }

  // ========== Geofence Operations ==========

  Future<GeofenceEntity> saveGeofence(GeofenceEntity entity) async {
    return await _executeInsert(
      entityName: 'geofence',
      table: LocalDatabaseProperties.geofenceTableName,
      values: entity.toMap(),
      createEntity: (id) => entity.copyWith(id: id),
      entityDetails: 'Geofence: ${entity.name}',
    );
  }

  Future<int> updateGeofence(GeofenceEntity entity) async {
    return await _executeUpdate(
      entityName: 'Geofence',
      entityId: entity.id,
      table: LocalDatabaseProperties.geofenceTableName,
      values: entity.toMap(),
      entityDetails: 'Geofence: ${entity.name}',
    );
  }

  Future<List<GeofenceEntity>> findAllGeofences() async {
    return await _executeQuery(
      entityName: 'geofence',
      table: LocalDatabaseProperties.geofenceTableName,
      fromMap: GeofenceEntity.fromMap,
      orderBy: 'name ASC',
    );
  }

  Future<void> deleteGeofence(int id) async {
    return await _executeDelete(
      entityName: 'geofence',
      table: LocalDatabaseProperties.geofenceTableName,
      id: id,
    );
  }

  Future<void> updateGeofenceActiveStatus(int id, bool isActive) async {
    try {
      await _db.update(
        LocalDatabaseProperties.geofenceTableName,
        {'is_active': isActive ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to update geofence active status',
        details: 'ID: $id, isActive: $isActive',
        originalError: e,
      );
    }
  }

  // ========== GeofenceRecord Operations ==========

  Future<GeofenceRecordEntity> saveGeofenceRecord(
    GeofenceRecordEntity entity,
  ) async {
    return await _executeInsert(
      entityName: 'geofence record',
      table: LocalDatabaseProperties.recordTableName,
      values: entity.toMap(),
      createEntity: (id) => entity.copyWith(id: id),
      entityDetails: 'Geofence: ${entity.geofenceName}',
    );
  }

  Future<int> updateGeofenceRecord(GeofenceRecordEntity entity) async {
    return await _executeUpdate(
      entityName: 'Geofence record',
      entityId: entity.id,
      table: LocalDatabaseProperties.recordTableName,
      values: entity.toMap(),
      entityDetails: 'Geofence: ${entity.geofenceName}',
    );
  }

  Future<List<GeofenceRecordEntity>> findAllGeofenceRecords() async {
    return await _executeQuery(
      entityName: 'geofence record',
      table: LocalDatabaseProperties.recordTableName,
      fromMap: GeofenceRecordEntity.fromMap,
      orderBy: 'created_at DESC',
    );
  }

  Future<void> deleteGeofenceRecord(int id) async {
    return await _executeDelete(
      entityName: 'geofence record',
      table: LocalDatabaseProperties.recordTableName,
      id: id,
    );
  }

  Future<void> deleteAllGeofenceRecords() async {
    return await _executeDelete(
      entityName: 'all geofence records',
      table: LocalDatabaseProperties.recordTableName,
      additionalDetails: 'Deleting all records',
    );
  }
}
