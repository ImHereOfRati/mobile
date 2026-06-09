import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final String imhereResponseCode;
  final String message;
  final T? data;

  ApiResponse({
    required this.imhereResponseCode,
    required this.message,
    this.data,
  });

  factory ApiResponse.success({T? data, String message = "OK"}) {
    return ApiResponse(
      imhereResponseCode: "SUCCESS",
      message: message,
      data: data,
    );
  }

  factory ApiResponse.fail({
    required String imhereErrorCode,
    required String errorMessage,
    T? data,
  }) {
    return ApiResponse(
      imhereResponseCode: imhereErrorCode,
      message: errorMessage,
      data: data,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}
