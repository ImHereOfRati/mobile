import 'package:iamhere/feature/friend/service/dto/friend_restriction_response_dto.dart';

abstract class FriendRestrictionServiceInterface {
  Future<List<FriendRestrictionResponseDto>> fetchRestrictions();
  Future<bool> deleteRestriction(String friendRestrictionId);
}
