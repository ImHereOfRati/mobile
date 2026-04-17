import 'package:iamhere/core/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'notification_local_repository.dart';

part 'notification_local_repository_provider.g.dart';

@riverpod
NotificationLocalRepository notificationLocalRepository(Ref ref) {
  return getIt<NotificationLocalRepository>();
}
