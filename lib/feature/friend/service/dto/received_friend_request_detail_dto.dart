import 'package:json_annotation/json_annotation.dart';

import 'friend_user_summary_dto.dart';

part 'received_friend_request_detail_dto.g.dart';

@JsonSerializable()
class ReceivedFriendRequestDetailDto {
  final String id;
  final FriendUserSummaryDto requester;
  final FriendUserSummaryDto receiver;
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceivedFriendRequestDetailDto({
    required this.id,
    required this.requester,
    required this.receiver,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  String get friendRequestId => id;
  String get requesterEmail => requester.email;
  String get requesterNickname => requester.nickname;

  factory ReceivedFriendRequestDetailDto.fromJson(Map<String, dynamic> json) =>
      _$ReceivedFriendRequestDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ReceivedFriendRequestDetailDtoToJson(this);
}
