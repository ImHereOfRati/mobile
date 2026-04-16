import 'dart:async';

import 'package:iamhere/core/database/local_database_exception.dart';
import 'package:sqflite/sqflite.dart';

abstract class AbstractLocalDatabaseService {
  final Database database;

  AbstractLocalDatabaseService(this.database);

  Future<T> executeInsert<T>({
    required String entityName,
    required String table,
    required Map<String, dynamic> values,
    required T Function(int id) createEntity,
    String? entityDetails,
  }) async {
    try {
      final id = await database.insert(
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

  Future<int> executeUpdate({
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
      final count = await database.update(
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

  Future<List<T>> executeQuery<T>({
    required String entityName,
    required String table,
    required T Function(Map<String, dynamic>) fromMap,
    String? orderBy,
  }) async {
    try {
      final result = await database.query(table, orderBy: orderBy);
      return result.map((json) => fromMap(json)).toList();
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to fetch ${entityName}s',
        originalError: e,
      );
    }
  }

  Future<void> executeDelete({
    required String entityName,
    required String table,
    int? id,
    String? additionalDetails,
  }) async {
    try {
      if (id != null) {
        await database.delete(table, where: 'id = ?', whereArgs: [id]);
      } else {
        await database.delete(table);
      }
    } catch (e) {
      throw LocalDatabaseException(
        'Failed to delete $entityName',
        details: id != null ? 'ID: $id' : additionalDetails,
        originalError: e,
      );
    }
  }
}
