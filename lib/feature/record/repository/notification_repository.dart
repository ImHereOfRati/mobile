import 'notification_entity.dart';

abstract class NotificationRepository {
  Future<NotificationEntity> save(NotificationEntity entity);

  Future<List<NotificationEntity>> findAllOrderByCreatedAtDesc();

  Future<void> deleteAll();
}
