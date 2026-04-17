import 'package:iamhere/core/database/service/notification_database_service.dart';
import 'package:injectable/injectable.dart';

import 'notification_entity.dart';
import 'notification_repository.dart';

@lazySingleton
class NotificationLocalRepository implements NotificationRepository {
  final NotificationDatabaseService _notificationDatabase;
  NotificationLocalRepository(this._notificationDatabase);

  @override
  Future<List<NotificationEntity>> findAllOrderByCreatedAtDesc() async {
    return await _notificationDatabase.findAll();
  }

  @override
  Future<NotificationEntity> save(NotificationEntity entity) async {
    return await _notificationDatabase.save(entity);
  }

  @override
  Future<void> deleteAll() async {
    await _notificationDatabase.deleteAll();
  }
}
