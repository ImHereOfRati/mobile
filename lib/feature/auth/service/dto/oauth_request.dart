import 'package:json_annotation/json_annotation.dart';

part 'oauth_request.g.dart';

@JsonSerializable()
class OAuthRequestDto {
  final String provider;
  final String idToken;

  OAuthRequestDto({required this.provider, required this.idToken});

  factory OAuthRequestDto.fromJson(Map<String, dynamic> json) =>
      _$OAuthRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OAuthRequestDtoToJson(this);
}
