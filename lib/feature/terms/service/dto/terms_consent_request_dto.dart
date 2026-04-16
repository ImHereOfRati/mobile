import 'package:json_annotation/json_annotation.dart';

part 'terms_consent_request_dto.g.dart';

@JsonSerializable()
class TermsConsentItemDto {
  final int termDefinitionId;
  final bool agreed;

  const TermsConsentItemDto({
    required this.termDefinitionId,
    required this.agreed,
  });

  factory TermsConsentItemDto.fromJson(Map<String, dynamic> json) =>
      _$TermsConsentItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TermsConsentItemDtoToJson(this);
}

@JsonSerializable()
class TermsAllConsentRequestDto {
  final List<TermsConsentItemDto> consents;

  const TermsAllConsentRequestDto({required this.consents});

  factory TermsAllConsentRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TermsAllConsentRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TermsAllConsentRequestDtoToJson(this);
}
