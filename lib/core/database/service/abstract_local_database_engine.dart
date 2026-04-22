import 'dart:async';

import 'package:iamhere/core/database/local_database_exception.dart';
import 'package:iamhere/core/database/util/database_handler.dart';
import 'package:sqflite/sqflite.dart';

abstract class AbstractLocalDatabaseService with DatabaseHandler {
  final Database database;

  AbstractLocalDatabaseService(this.database);

  Future<T> executeInsert<T>({
    required String entityName,
    required String table,
    required Map<String, dynamic> values,
    required T Function(int id) createEntity,
    String? entityDetails,
  }) async {
    return safeDbCall(() async {
      int id = await _insertEntity(table, values);
      return createEntity(id);
    });
  }

  Future<int> executeUpdate({
    required String entityName,
    required int? entityId,
    required String table,
    required Map<String, dynamic> values,
    String? entityDetails,
  }) async {
    return safeDbCall(() async {
      _validateEntityIdExistence(entityId, entityName, entityDetails);
      return await _updateEntity(table, values, entityId, entityName);
    });
  }

  Future<List<T>> executeQuery<T>({
    required String entityName,
    required String table,
    required T Function(Map<String, dynamic>) fromMap,
    String? orderBy,
  }) async {
    return safeDbCall(() async {
      final result = await database.query(table, orderBy: orderBy);
      return result.map((json) => fromMap(json)).toList();
    });
  }

  Future<void> executeDelete({
    required String entityName,
    required String table,
    int? id,
    String? additionalDetails,
  }) async {
    return safeDbCall(() async {
      if (id != null) {
        await database.delete(table, where: 'id = ?', whereArgs: [id]);
      } else {
        await database.delete(table);
      }
    });
  }

  Future<int> _insertEntity(String table, Map<String, dynamic> values) async {
    final id = await database.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return id;
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
        '$entityName not found',
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
        'Cannot update $entityName without ID',
        details: entityDetails,
      );
    }
  }
}
