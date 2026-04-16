import 'package:json_annotation/json_annotation.dart';

part 'create_friend_request_dto.g.dart';

@JsonSerializable()
class CreateFriendRequestDto {
  final String receiverId;
  final String receiverEmail;
  final String message;

  CreateFriendRequestDto({
    required this.receiverId,
    required this.receiverEmail,
    required this.message,
  });

  factory CreateFriendRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFriendRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateFriendRequestDtoToJson(this);
}
