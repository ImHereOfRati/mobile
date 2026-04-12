import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class APIResponse<T> {
  final int code;
  final String? message;
  final T data;

  APIResponse({required this.code, required this.message, required this.data});

  factory APIResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$APIResponseFromJson(json, fromJsonT);
}

@JsonSerializable(genericArgumentFactories: true)
class PageResponse<T> {
  final List<T> content; // 실제 데이터 리스트
  final int totalPages; // 전체 페이지 수
  final int totalElements; // 전체 요소 수
  final int number; // 현재 페이지 번호 (0부터 시작)
  final int size; // 페이지 당 사이즈
  final bool last; // 마지막 페이지 여부

  PageResponse({
    required this.content,
    required this.totalPages,
    required this.totalElements,
    required this.number,
    required this.size,
    required this.last,
  });

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PageResponseFromJson(json, fromJsonT);
}
