import 'package:json_annotation/json_annotation.dart';

part 'create_friend_request_response_dto.g.dart';

@JsonSerializable()
class CreateFriendRequestResponseDto {
  final int friendRequestId;

  CreateFriendRequestResponseDto({
    required this.friendRequestId,
  });

  factory CreateFriendRequestResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFriendRequestResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateFriendRequestResponseDtoToJson(this);
}
