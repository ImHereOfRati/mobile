import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final String? status;

  AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    this.status,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);
}
