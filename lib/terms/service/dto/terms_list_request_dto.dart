import 'package:iamhere/terms/service/dto/terms_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'terms_list_request_dto.g.dart';

@JsonSerializable()
class TermsListRequestDto {
  final int termDefinitionId;
  final String title;
  final TermsType termsTypes;
  final bool isRequired;

  TermsListRequestDto({
    required this.termDefinitionId,
    required this.title,
    required this.termsTypes,
    required this.isRequired,
  });

  factory TermsListRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TermsListRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TermsListRequestDtoToJson(this);
}
