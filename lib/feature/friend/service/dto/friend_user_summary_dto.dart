import 'package:json_annotation/json_annotation.dart';

part 'friend_user_summary_dto.g.dart';

@JsonSerializable()
class FriendUserSummaryDto {
  final String id;
  final String email;
  final String nickname;
  final String oAuth2Provider;

  FriendUserSummaryDto({
    required this.id,
    required this.email,
    required this.nickname,
    required this.oAuth2Provider,
  });

  factory FriendUserSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$FriendUserSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FriendUserSummaryDtoToJson(this);
}
