import 'package:json_annotation/json_annotation.dart';

part 'update_friend_alias_request_dto.g.dart';

@JsonSerializable()
class UpdateFriendAliasRequestDto {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? friendRelationshipId;
  @JsonKey(name: 'alias')
  final String alias;

  UpdateFriendAliasRequestDto({this.friendRelationshipId, required this.alias});

  String get newFriendAlias => alias;

  factory UpdateFriendAliasRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateFriendAliasRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateFriendAliasRequestDtoToJson(this);
}
