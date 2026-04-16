import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/update_friend_alias_request_dto.dart';
import 'package:iamhere/feature/friend/service/friend_relationship_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_list_view_model.g.dart';

@riverpod
class FriendListViewModel extends _$FriendListViewModel {
  late final FriendRelationshipServiceInterface _service;

  @override
  Future<List<FriendRelationshipResponseDto>> build() async {
    _service = getIt<FriendRelationshipServiceInterface>();
    return _service.fetchFriendList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.fetchFriendList());
  }

  Future<bool> updateAlias(
      String friendRelationshipId, String newAlias) async {
    final result = await _service.updateAlias(UpdateFriendAliasRequestDto(
      friendRelationshipId: friendRelationshipId,
      newFriendAlias: newAlias,
    ));
    if (result != null) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> blockFriend(String friendRelationshipId) async {
    final result = await _service.blockFriend(friendRelationshipId);
    if (result) await refresh();
    return result;
  }

  Future<bool> deleteFriend(String friendRelationshipId) async {
    final result = await _service.deleteFriend(friendRelationshipId);
    if (result) await refresh();
    return result;
  }
}
