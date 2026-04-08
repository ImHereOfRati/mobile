import 'package:json_annotation/json_annotation.dart';

part 'terms_version_response.g.dart';

@JsonSerializable()
class TermsVersionResponse {
  final String version;
  final String content;
  final DateTime effectiveDate;

  TermsVersionResponse({
    required this.version,
    required this.content,
    required this.effectiveDate,
  });

  factory TermsVersionResponse.fromJson(Map<String, dynamic> json) =>
      _$TermsVersionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TermsVersionResponseToJson(this);
}
