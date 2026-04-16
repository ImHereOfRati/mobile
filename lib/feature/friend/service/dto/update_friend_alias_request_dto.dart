import 'package:json_annotation/json_annotation.dart';

part 'update_friend_alias_request_dto.g.dart';

@JsonSerializable()
class UpdateFriendAliasRequestDto {
  final String friendRelationshipId;
  final String newFriendAlias;

  UpdateFriendAliasRequestDto({
    required this.friendRelationshipId,
    required this.newFriendAlias,
  });

  factory UpdateFriendAliasRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateFriendAliasRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateFriendAliasRequestDtoToJson(this);
}
