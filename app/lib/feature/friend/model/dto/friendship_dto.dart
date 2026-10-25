import 'package:iamhere/feature/friend/model/dto/friend_user_dto.dart';

class FriendshipDto {
  final String id;
  final FriendUserDto friend;
  final String friendAlias;
  final String createdAt;

  const FriendshipDto({
    required this.id,
    required this.friend,
    required this.friendAlias,
    required this.createdAt,
  });

  /// 별명이 있으면 별명, 없으면 상대의 닉네임.
  String get displayName =>
      friendAlias.trim().isEmpty ? friend.nickname : friendAlias.trim();

  /// 친구가 된 날을 일 단위(yyyy-MM-dd)까지만 보여 준다.
  String get createdDay =>
      createdAt.length >= 10 ? createdAt.substring(0, 10) : '-';

  factory FriendshipDto.fromJson(Map<String, dynamic> json) => FriendshipDto(
    id: json['id']?.toString() ?? '',
    friend: FriendUserDto.fromJson(
      (json['friend'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    friendAlias: json['friendAlias'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
  );
}
