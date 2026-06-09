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
