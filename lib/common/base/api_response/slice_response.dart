import 'package:json_annotation/json_annotation.dart';

part 'slice_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class SliceResponse<T> {
  final List<T> content;
  final bool hasNext;

  SliceResponse({
    required this.content,
    required this.hasNext,
  });

  factory SliceResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
      ) =>
      _$SliceResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$SliceResponseToJson(this, toJsonT);
}