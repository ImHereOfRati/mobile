import 'package:json_annotation/json_annotation.dart';

import 'terms_type.dart';

part 'terms_list_request_dto.g.dart';

@JsonSerializable()
class TermsListRequestDto {
  final int id;
  final int version;
  final TermsType type;
  final String title;
  final String content;
  final DateTime effectiveDate;
  final bool isRequired;

  TermsListRequestDto({
    required this.id,
    required this.version,
    required this.type,
    required this.title,
    required this.content,
    required this.effectiveDate,
    required this.isRequired,
  });

  factory TermsListRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TermsListRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TermsListRequestDtoToJson(this);
}
