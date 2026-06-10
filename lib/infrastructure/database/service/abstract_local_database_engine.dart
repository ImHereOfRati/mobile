import 'dart:async';

import 'package:iamhere/infrastructure/database/local_database_exception.dart';
import 'package:iamhere/infrastructure/database/util/database_handler.dart';
import 'package:sqflite/sqflite.dart';

abstract class AbstractLocalDatabaseService with DatabaseHandler {
  static const _missingIdMessageTemplate = 'Cannot update {entity} without ID';
  static const _notFoundMessageTemplate = '{entity} not found';

  final Database database;

  AbstractLocalDatabaseService(this.database);

  Future<T> saveEntity<T>({
    required String entityName,
    required String table,
    required Map<String, dynamic> values,
    required T Function(int id) createEntity,
    String? entityDetails,
  }) {
    return executeInsert(
      entityName: entityName,
      table: table,
      values: values,
      createEntity: createEntity,
      entityDetails: entityDetails,
    );
  }

  Future<List<T>> findAllEntities<T>({
    required String entityName,
    required String table,
    required T Function(Map<String, dynamic>) fromMap,
    String? orderBy,
  }) {
    return executeQuery(
      entityName: entityName,
      table: table,
      fromMap: fromMap,
      orderBy: orderBy,
    );
  }

  Future<void> deleteAllEntities({
    required String entityName,
    required String table,
    String? additionalDetails,
  }) {
    return executeDelete(
      entityName: entityName,
      table: table,
      additionalDetails: additionalDetails,
    );
  }

  Future<void> deleteEntityById({
    required String entityName,
    required String table,
    required int id,
  }) {
    return executeDelete(entityName: entityName, table: table, id: id);
  }

  Future<T> executeInsert<T>({
    required String entityName,
    required String table,
    required Map<String, dynamic> values,
    required T Function(int id) createEntity,
    String? entityDetails,
  }) {
    return safeDbCall(
      () async {
        final id = await _insertEntity(table, values);
        return createEntity(id);
      },
      operation: 'Failed to save $entityName',
      details: entityDetails,
    );
  }

  Future<int> executeUpdate({
    required String entityName,
    required int? entityId,
    required String table,
    required Map<String, dynamic> values,
    String? entityDetails,
  }) {
    return safeDbCall(
      () async {
        _validateEntityIdExistence(entityId, entityName, entityDetails);
        return _updateEntity(table, values, entityId, entityName);
      },
      operation: 'Failed to update $entityName',
      details: entityDetails ?? 'ID: $entityId',
    );
  }

  Future<List<T>> executeQuery<T>({
    required String entityName,
    required String table,
    required T Function(Map<String, dynamic>) fromMap,
    String? orderBy,
  }) {
    return safeDbCall(
      () async {
        final result = await database.query(table, orderBy: orderBy);
        return result.map(fromMap).toList();
      },
      operation: 'Failed to fetch ${entityName}s',
    );
  }

  Future<List<T>> executeRawQuery<T>({
    required String entityName,
    required String sql,
    required T Function(Map<String, dynamic>) fromMap,
    List<Object?>? arguments,
  }) {
    return safeDbCall(
      () async {
        final result = await database.rawQuery(sql, arguments);
        return result.map(fromMap).toList();
      },
      operation: 'Failed to fetch ${entityName}s',
    );
  }

  Future<void> executeDelete({
    required String entityName,
    required String table,
    int? id,
    String? where,
    List<Object?>? whereArgs,
    String? additionalDetails,
  }) {
    return safeDbCall(
      () async {
        if (id != null) {
          await database.delete(table, where: 'id = ?', whereArgs: [id]);
        } else if (where != null) {
          await database.delete(table, where: where, whereArgs: whereArgs);
        } else {
          await database.delete(table);
        }
      },
      operation: 'Failed to delete $entityName',
      details: additionalDetails ?? (id != null ? 'ID: $id' : null),
    );
  }

  Future<int> executePartialUpdate({
    required String entityName,
    required String table,
    required Map<String, dynamic> values,
    required int id,
    String? entityDetails,
  }) {
    return safeDbCall(
      () async {
        return await database.update(
          table,
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
      },
      operation: 'Failed to update $entityName',
      details: entityDetails ?? 'ID: $id',
    );
  }

  Future<int> _insertEntity(String table, Map<String, dynamic> values) {
    return database.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> _updateEntity(
    String table,
    Map<String, dynamic> values,
    int? entityId,
    String entityName,
  ) async {
    final count = await database.update(
      table,
      values,
      where: 'id = ?',
      whereArgs: [entityId],
    );
    _validateUpdateAffectedRowCount(count, entityName, entityId);
    return count;
  }

  void _validateUpdateAffectedRowCount(
    int count,
    String entityName,
    int? entityId,
  ) {
    if (count == 0) {
      throw LocalDatabaseException(
        _notFoundMessageTemplate.replaceFirst('{entity}', entityName),
        details: 'ID: $entityId',
      );
    }
  }

  void _validateEntityIdExistence(
    int? entityId,
    String entityName,
    String? entityDetails,
  ) {
    if (entityId == null) {
      throw LocalDatabaseException(
        _missingIdMessageTemplate.replaceFirst('{entity}', entityName),
        details: entityDetails,
      );
    }
  }
}
