import 'package:json_annotation/json_annotation.dart';

part 'user_me_response_dto.g.dart';

@JsonSerializable()
class UserMeResponseDto {
  final String userEmail;
  final String userNickname;

  UserMeResponseDto({
    required this.userEmail,
    required this.userNickname,
  });

  factory UserMeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserMeResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserMeResponseDtoToJson(this);
}
