import 'dart:async';

import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/repository/notification_local_repository.dart';
import 'package:iamhere/feature/record/repository/notification_local_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_view_model.g.dart';

@riverpod
class NotificationViewModel extends _$NotificationViewModel {
  late final NotificationLocalRepository _repository;
  Timer? _pollTimer;

  @override
  Future<List<NotificationEntity>> build() async {
    _repository = ref.watch(notificationLocalRepositoryProvider);
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => _silentRefresh(),
    );
    ref.onDispose(() {
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    return await _repository.findAllOrderByCreatedAtDesc();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _repository.findAllOrderByCreatedAtDesc();
    });
  }

  Future<void> _silentRefresh() async {
    final current = state.asData?.value;
    final next = await AsyncValue.guard(
      () => _repository.findAllOrderByCreatedAtDesc(),
    );
    if (next.hasError && current != null) return;
    state = next;
  }

  Future<void> deleteAll() async {
    await _repository.deleteAll();
    await refresh();
  }
}
