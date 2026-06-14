import 'package:json_annotation/json_annotation.dart';

part 'after_terms_agreement_auth_response_dto.g.dart';

@JsonSerializable()
class AfterTermsAgreementAuthResponseDto {
  final String accessToken;
  final String refreshToken;
  final bool? isActive;
  final String? userStatus;

  AfterTermsAgreementAuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    this.isActive,
    this.userStatus,
  });

  factory AfterTermsAgreementAuthResponseDto.fromJson(
    Map<String, dynamic> json,
  ) => _$AfterTermsAgreementAuthResponseDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$AfterTermsAgreementAuthResponseDtoToJson(this);
}
