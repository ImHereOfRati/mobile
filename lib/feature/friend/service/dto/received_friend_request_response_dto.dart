import 'package:json_annotation/json_annotation.dart';

part 'received_friend_request_response_dto.g.dart';

@JsonSerializable()
class ReceivedFriendRequestResponseDto {
  final int friendRequestId;
  final String requesterEmail;
  final String requesterNickname;

  ReceivedFriendRequestResponseDto({
    required this.friendRequestId,
    required this.requesterEmail,
    required this.requesterNickname,
  });

  factory ReceivedFriendRequestResponseDto.fromJson(
          Map<String, dynamic> json) =>
      _$ReceivedFriendRequestResponseDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ReceivedFriendRequestResponseDtoToJson(this);
}
