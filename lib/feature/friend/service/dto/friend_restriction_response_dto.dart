import 'package:json_annotation/json_annotation.dart';

part 'friend_restriction_response_dto.g.dart';

@JsonSerializable()
class FriendRestrictionResponseDto {
  final int friendRestrictionId;
  final String targetEmail;
  final String targetNickname;
  final String restrictionType;
  final String createdAt;

  FriendRestrictionResponseDto({
    required this.friendRestrictionId,
    required this.targetEmail,
    required this.targetNickname,
    required this.restrictionType,
    required this.createdAt,
  });

  factory FriendRestrictionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FriendRestrictionResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRestrictionResponseDtoToJson(this);
}
