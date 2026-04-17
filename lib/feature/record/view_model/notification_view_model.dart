import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/repository/notification_local_repository.dart';
import 'package:iamhere/feature/record/repository/notification_local_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_view_model.g.dart';

@riverpod
class NotificationViewModel extends _$NotificationViewModel {
  late final NotificationLocalRepository _repository;

  @override
  Future<List<NotificationEntity>> build() async {
    _repository = ref.watch(notificationLocalRepositoryProvider);
    return await _repository.findAllOrderByCreatedAtDesc();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.findAllOrderByCreatedAtDesc();
    });
  }

  Future<void> deleteAll() async {
    await _repository.deleteAll();
    await refresh();
  }
}
