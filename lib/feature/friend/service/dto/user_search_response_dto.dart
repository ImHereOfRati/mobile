import 'package:json_annotation/json_annotation.dart';

part 'user_search_response_dto.g.dart';

@JsonSerializable()
class UserSearchResponseDto {
  final String id;
  final String email;
  final String nickname;
  final String oAuth2Provider;

  UserSearchResponseDto({
    required this.id,
    required this.email,
    required this.nickname,
    required this.oAuth2Provider,
  });

  String get userId => id;
  String get userEmail => email;
  String get userNickname => nickname;

  factory UserSearchResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserSearchResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserSearchResponseDtoToJson(this);
}
