import 'package:json_annotation/json_annotation.dart';

part 'friend_relationship_response_dto.g.dart';

@JsonSerializable()
class FriendRelationshipResponseDto {
  final String friendRelationshipId;
  final String friendEmail;
  final String friendAlias;

  FriendRelationshipResponseDto({
    required this.friendRelationshipId,
    required this.friendEmail,
    required this.friendAlias,
  });

  factory FriendRelationshipResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FriendRelationshipResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRelationshipResponseDtoToJson(this);
}
