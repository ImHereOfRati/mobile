import 'package:iamhere/core/database/local_database_properties.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:injectable/injectable.dart';

import 'abstract_local_database_engine.dart';

@singleton
class NotificationDatabaseService extends AbstractLocalDatabaseService {
  NotificationDatabaseService(super.database);

  Future<NotificationEntity> save(NotificationEntity entity) => executeInsert(
    entityName: 'notification',
    table: LocalDatabaseProperties.notificationTableName,
    values: entity.toMap(),
    createEntity: (id) => entity.copyWith(id: id),
    entityDetails: 'Notification: ${entity.title}',
  );

  Future<List<NotificationEntity>> findAll() => executeQuery(
    entityName: 'notification',
    table: LocalDatabaseProperties.notificationTableName,
    fromMap: NotificationEntity.fromMap,
    orderBy: 'created_at DESC',
  );

  Future<void> deleteAll() => executeDelete(
    entityName: 'all notifications',
    table: LocalDatabaseProperties.notificationTableName,
    additionalDetails: 'Deleting all notifications',
  );
}
