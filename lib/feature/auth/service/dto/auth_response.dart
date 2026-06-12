import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final String? userStatus;

  AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    this.userStatus,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);
}
