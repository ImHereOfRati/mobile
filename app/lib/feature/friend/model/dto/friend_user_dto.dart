class FriendUserDto {
  final String id;
  final String email;
  final String nickname;
  final String oAuth2Provider;

  const FriendUserDto({
    required this.id,
    required this.email,
    required this.nickname,
    required this.oAuth2Provider,
  });

  factory FriendUserDto.fromJson(Map<String, dynamic> json) => FriendUserDto(
    id: json['id']?.toString() ?? '',
    email: json['email'] as String? ?? '',
    nickname: json['nickname'] as String? ?? '',
    oAuth2Provider: json['oAuth2Provider'] as String? ?? '',
  );
}
