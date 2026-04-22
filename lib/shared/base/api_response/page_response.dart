import 'package:json_annotation/json_annotation.dart';

part 'page_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  final List<T> content;
  final int totalPages;
  final int totalElements;
  final int number; // 페이지 번호 (0-based)
  final int size; // 페이지 당 요소 수
  final bool last; // 마지막 페이지 여부
  final bool first; // 첫 페이지 여부 (추가 권장)

  PageResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
    required this.last,
    required this.first,
  });

  // 제네릭 T를 처리하기 위한 팩토리 메서드
  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PageResponseFromJson(json, fromJsonT);
}
