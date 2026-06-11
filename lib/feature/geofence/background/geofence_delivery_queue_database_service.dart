import 'package:iamhere/feature/geofence/background/geofence_delivery_queue_entity.dart';
import 'package:iamhere/infrastructure/database/local_database_properties.dart';
import 'package:iamhere/infrastructure/database/local_database_exception.dart';
import 'package:iamhere/infrastructure/database/service/abstract_local_database_engine.dart';

class GeofenceDeliveryQueueDatabaseService extends AbstractLocalDatabaseService {
  static const _processingStaleAfter = Duration(minutes: 15);

  GeofenceDeliveryQueueDatabaseService(super.database);

  Future<GeofenceDeliveryQueueEntity?> enqueue(
    GeofenceDeliveryQueueEntity entity,
  ) async {
    try {
      return await saveEntity(
        entityName: 'geofence delivery queue item',
        table: LocalDatabaseProperties.geofenceDeliveryQueueTableName,
        values: entity.toMap(),
        createEntity: (id) => entity.copyWith(id: id),
        entityDetails: 'Dedupe: ${entity.dedupeKey}',
      );
    } on LocalDatabaseException catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('unique') || msg.contains('duplicate')) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<GeofenceDeliveryQueueEntity>> takeDue({int limit = 10}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final staleThreshold = DateTime.now()
        .toUtc()
        .subtract(_processingStaleAfter)
        .toIso8601String();
    return await executeRawQuery(
      entityName: 'geofence delivery queue item',
      sql: '''
        SELECT *
        FROM ${LocalDatabaseProperties.geofenceDeliveryQueueTableName}
        WHERE (status = ? AND next_attempt_at <= ?)
           OR (status = ? AND updated_at <= ?)
        ORDER BY created_at ASC
        LIMIT ?
      ''',
      arguments: [
        GeofenceDeliveryQueueEntity.pending,
        now,
        GeofenceDeliveryQueueEntity.processing,
        staleThreshold,
        limit,
      ],
      fromMap: GeofenceDeliveryQueueEntity.fromMap,
    );
  }

  Future<bool> claim(int id) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final staleThreshold = DateTime.now()
        .toUtc()
        .subtract(_processingStaleAfter)
        .toIso8601String();
    final count = await database.update(
      LocalDatabaseProperties.geofenceDeliveryQueueTableName,
      {
        'status': GeofenceDeliveryQueueEntity.processing,
        'updated_at': now,
      },
      where: '''
        id = ? AND (
          (status = ? AND next_attempt_at <= ?)
          OR (status = ? AND updated_at <= ?)
        )
      ''',
      whereArgs: [
        id,
        GeofenceDeliveryQueueEntity.pending,
        now,
        GeofenceDeliveryQueueEntity.processing,
        staleThreshold,
      ],
    );
    return count > 0;
  }

  Future<void> complete(int id) async {
    await deleteEntityById(
      entityName: 'geofence delivery queue item',
      table: LocalDatabaseProperties.geofenceDeliveryQueueTableName,
      id: id,
    );
  }

  Future<void> reschedule({
    required int id,
    required int retryCount,
    required String lastError,
  }) async {
    final now = DateTime.now().toUtc();
    final delayMinutes = _backoffMinutes(retryCount);
    final nextAttemptAt = now.add(Duration(minutes: delayMinutes));
    await executePartialUpdate(
      entityName: 'geofence delivery queue item',
      table: LocalDatabaseProperties.geofenceDeliveryQueueTableName,
      id: id,
      values: {
        'status': GeofenceDeliveryQueueEntity.pending,
        'retry_count': retryCount,
        'next_attempt_at': nextAttemptAt.toIso8601String(),
        'last_error': lastError,
        'updated_at': now.toIso8601String(),
      },
      entityDetails: 'ID: $id',
    );
  }

  int _backoffMinutes(int retryCount) {
    final capped = retryCount.clamp(0, 4);
    return [1, 5, 15, 30, 60][capped];
  }
}
