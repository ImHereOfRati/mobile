import 'package:iamhere/feature/friend/model/dto/friend_user_dto.dart';

class FriendRestrictionDto {
  final String id;
  final FriendUserDto restricted;
  final String type;

  const FriendRestrictionDto({
    required this.id,
    required this.restricted,
    required this.type,
  });

  bool get isBlock => type == 'BLOCK';

  factory FriendRestrictionDto.fromJson(Map<String, dynamic> json) =>
      FriendRestrictionDto(
        id: json['id']?.toString() ?? '',
        restricted: FriendUserDto.fromJson(
          (json['restricted'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        type: json['type'] as String? ?? '',
      );
}
