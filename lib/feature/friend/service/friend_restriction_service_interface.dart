import 'package:iamhere/feature/friend/service/dto/friend_restriction_deleted_response_dto.dart';
import 'package:iamhere/feature/friend/service/dto/friend_restriction_response_dto.dart';

abstract class FriendRestrictionServiceInterface {
  Future<List<FriendRestrictionResponseDto>> fetchRestrictions();
  Future<FriendRestrictionDeletedResponseDto?> deleteRestriction(
      int friendRestrictionId);
}
