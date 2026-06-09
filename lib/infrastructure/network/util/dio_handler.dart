import 'package:dio/dio.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/infrastructure/network/response/api_response.dart';

import '../../../common/base/result/error_analyst.dart';

mixin DioHandler {
  Future<ApiResponse<T>> safeApiCall<T>(
    Future<ApiResponse<T>> Function() call,
  ) async {
    try {
      return await call();
    } on DioException catch (e, stack) {
      ErrorAnalyst.log(ResultMessage.dioException.toString(), stack);
      return mapToApiResponse<T>(e);
    } catch (e, stack) {
      ErrorAnalyst.log("UNKNOWN Error: ${e.toString()}", stack);
      return ApiResponse.fail(
        imhereErrorCode: 'UNKNOWN_ERROR',
        errorMessage: e.toString(),
      );
    }
  }

  ApiResponse<T> mapToApiResponse<T>(DioException exception) {
    final responseData = exception.response?.data;

    if (responseData is Map<String, dynamic>) {
      try {
        final errorResponse = ApiResponse<dynamic>.fromJson(
          responseData,
          (json) => null,
        );
        return ApiResponse.fail(
          imhereErrorCode: errorResponse.imhereResponseCode,
          errorMessage: errorResponse.message,
        );
      } catch (_) {}
    }

    return ApiResponse.fail(
      imhereErrorCode: 'NETWORK_900',
      errorMessage: exception.message ?? ResultMessage.dioException.toString(),
    );
  }
}
