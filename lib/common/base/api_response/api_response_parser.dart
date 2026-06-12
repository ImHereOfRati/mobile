import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/common/base/api_response/slice_response.dart';

typedef JsonMap = Map<String, dynamic>;
typedef JsonItemParser<T> = T Function(JsonMap json);

class ApiResponseParser {
  const ApiResponseParser._();

  static ApiResponse<T> parseObject<T>(
    dynamic raw,
    JsonItemParser<T> fromJson,
  ) {
    return ApiResponse<T>.fromJson(
      _asMap(raw),
      (json) => fromJson(_asMap(json)),
    );
  }

  static ApiResponse<List<T>> parseList<T>(
    dynamic raw,
    JsonItemParser<T> fromJson,
  ) {
    return ApiResponse<List<T>>.fromJson(_asMap(raw), (json) {
      if (json is! List) {
        throw const FormatException('Expected response data to be a List.');
      }

      return json.map((item) => fromJson(_asMap(item))).toList();
    });
  }

  static ApiResponse<SliceResponse<T>> parseSlice<T>(
    dynamic raw,
    JsonItemParser<T> fromJson,
  ) {
    return ApiResponse<SliceResponse<T>>.fromJson(
      _asMap(raw),
      (json) => SliceResponse<T>.fromJson(
        _asMap(json),
        (itemJson) => fromJson(_asMap(itemJson)),
      ),
    );
  }

  static ApiResponse<void> parseVoid(dynamic raw) {
    return ApiResponse<void>.fromJson(_asMap(raw), (_) {});
  }

  static JsonMap _asMap(dynamic value) {
    if (value is JsonMap) {
      return value;
    }

    throw FormatException(
      'Expected a JSON object but received ${value.runtimeType}.',
    );
  }
}
