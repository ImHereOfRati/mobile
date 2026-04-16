import 'package:json_annotation/json_annotation.dart';

part 'terms_version_response_dto.g.dart';

@JsonSerializable()
class TermsVersionResponseDto {
  final String version;
  final String content;
  final DateTime effectiveDate;

  TermsVersionResponseDto({
    required this.version,
    required this.content,
    required this.effectiveDate,
  });

  factory TermsVersionResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TermsVersionResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TermsVersionResponseDtoToJson(this);
}
