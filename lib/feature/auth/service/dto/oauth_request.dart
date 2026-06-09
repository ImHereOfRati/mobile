import 'package:json_annotation/json_annotation.dart';

part 'oauth_request_dto.g.dart';

@JsonSerializable()
class OAuthRequestDto {
  final String provider;
  final String idToken;

  OAuthRequestDto({required this.provider, required this.idToken});

  Map<String, dynamic> toJson() => _$OAuthRequestDtoToJson(this);
}
