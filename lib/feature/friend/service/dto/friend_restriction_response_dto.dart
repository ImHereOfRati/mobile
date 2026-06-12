import 'package:json_annotation/json_annotation.dart';

import 'friend_user_summary_dto.dart';

part 'friend_restriction_response_dto.g.dart';

@JsonSerializable()
class FriendRestrictionResponseDto {
  final String id;
  final FriendUserSummaryDto restrictor;
  final FriendUserSummaryDto restricted;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiredAt;

  FriendRestrictionResponseDto({
    required this.id,
    required this.restrictor,
    required this.restricted,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.expiredAt,
  });

  String get friendRestrictionId => id;
  String get targetEmail => restricted.email;
  String get targetNickname => restricted.nickname;
  String get restrictionType => type;

  factory FriendRestrictionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FriendRestrictionResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FriendRestrictionResponseDtoToJson(this);
}
