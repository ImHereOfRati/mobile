import 'package:iamhere/feature/friend/model/dto/friend_user_dto.dart';

class FriendRequestDto {
  final String id;
  final String message;
  final FriendUserDto requester;
  final FriendUserDto receiver;
  final String createdAt;

  const FriendRequestDto({
    required this.id,
    required this.message,
    required this.requester,
    required this.receiver,
    required this.createdAt,
  });

  factory FriendRequestDto.fromJson(Map<String, dynamic> json) {
    FriendUserDto user(String key) => FriendUserDto.fromJson(
      (json[key] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    return FriendRequestDto(
      id: json['id']?.toString() ?? '',
      message: json['message'] as String? ?? '',
      requester: user('requester'),
      receiver: user('receiver'),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
