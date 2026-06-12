import 'package:json_annotation/json_annotation.dart';

part 'user_me_response_dto.g.dart';

@JsonSerializable()
class UserMeResponseDto {
  final String id;
  final String email;
  final String nickname;
  final String oAuth2Provider;

  UserMeResponseDto({
    required this.id,
    required this.email,
    required this.nickname,
    required this.oAuth2Provider,
  });

  factory UserMeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserMeResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserMeResponseDtoToJson(this);
}
