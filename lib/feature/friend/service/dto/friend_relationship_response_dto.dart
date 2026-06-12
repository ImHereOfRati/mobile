import 'package:json_annotation/json_annotation.dart';

import 'friend_user_summary_dto.dart';

part 'friend_relationship_response_dto.g.dart';

@JsonSerializable()
class FriendRelationshipResponseDto {
  final String id;
  final FriendUserSummaryDto owner;
  final FriendUserSummaryDto friend;
  final String friendAlias;
  final DateTime createdAt;
  final DateTime updatedAt;

  FriendRelationshipResponseDto({
    required this.id,
    required this.owner,
    required this.friend,
    required this.friendAlias,
    required this.createdAt,
    required this.updatedAt,
  });

  String get friendRelationshipId => id;
  String get friendEmail => friend.email;

  factory FriendRelationshipResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FriendRelationshipResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRelationshipResponseDtoToJson(this);
}
