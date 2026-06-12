import 'package:json_annotation/json_annotation.dart';

import 'friend_user_summary_dto.dart';

part 'received_friend_request_response_dto.g.dart';

@JsonSerializable()
class ReceivedFriendRequestResponseDto {
  final String id;
  final FriendUserSummaryDto requester;
  final FriendUserSummaryDto receiver;
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceivedFriendRequestResponseDto({
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

  factory ReceivedFriendRequestResponseDto.fromJson(
    Map<String, dynamic> json,
  ) => _$ReceivedFriendRequestResponseDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ReceivedFriendRequestResponseDtoToJson(this);
}
