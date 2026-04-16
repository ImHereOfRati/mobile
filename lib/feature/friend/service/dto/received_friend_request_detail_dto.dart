import 'package:json_annotation/json_annotation.dart';

part 'received_friend_request_detail_dto.g.dart';

@JsonSerializable()
class ReceivedFriendRequestDetailDto {
  final int friendRequestId;
  final String requesterEmail;
  final String requesterNickname;
  final String message;

  ReceivedFriendRequestDetailDto({
    required this.friendRequestId,
    required this.requesterEmail,
    required this.requesterNickname,
    required this.message,
  });

  factory ReceivedFriendRequestDetailDto.fromJson(
          Map<String, dynamic> json) =>
      _$ReceivedFriendRequestDetailDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ReceivedFriendRequestDetailDtoToJson(this);
}
