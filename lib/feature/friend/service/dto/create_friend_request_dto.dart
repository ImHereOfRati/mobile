import 'package:json_annotation/json_annotation.dart';

part 'create_friend_request_dto.g.dart';

@JsonSerializable()
class CreateFriendRequestDto {
  @JsonKey(name: 'targetId')
  final String targetId;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? receiverEmail;
  final String message;

  CreateFriendRequestDto({
    required this.targetId,
    this.receiverEmail,
    required this.message,
  });

  String get receiverId => targetId;

  factory CreateFriendRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFriendRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateFriendRequestDtoToJson(this);
}
