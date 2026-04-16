import 'package:iamhere/feature/friend/service/dto/friend_relationship_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/update_friend_alias_request_dto.dart';

abstract class FriendRelationshipServiceInterface {
  Future<List<FriendRelationshipResponseDto>> fetchFriendList();
  Future<FriendRelationshipResponseDto?> updateAlias(
      UpdateFriendAliasRequestDto request);
  Future<bool> blockFriend(String friendRelationshipId);
  Future<bool> deleteFriend(String friendRelationshipId);
}
