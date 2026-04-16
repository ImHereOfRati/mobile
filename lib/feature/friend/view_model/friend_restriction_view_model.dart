import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/friend/service/dto/friend_restriction_response_dto.dart';
import 'package:iamhere/feature/friend/service/friend_restriction_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_restriction_view_model.g.dart';

@riverpod
class FriendRestrictionViewModel extends _$FriendRestrictionViewModel {
  late final FriendRestrictionServiceInterface _service;

  @override
  Future<List<FriendRestrictionResponseDto>> build() async {
    _service = getIt<FriendRestrictionServiceInterface>();
    return _service.fetchRestrictions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.fetchRestrictions());
  }

  Future<bool> unblock(int friendRestrictionId) async {
    final result = await _service.deleteRestriction(friendRestrictionId);
    if (result != null) {
      await refresh();
      return true;
    }
    return false;
  }
}
