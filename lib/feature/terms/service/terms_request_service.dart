import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

import 'dto/terms_list_request_dto.dart';

@lazySingleton
class TermsRequestService {
  static const String _termsListPath = '/api/terms';

  final Dio _dio;

  TermsRequestService(this._dio);

  Future<ApiResponse<List<TermsListRequestDto>>> requestTermsList() async {
    try {
      final response = await _dio.get(_termsListPath);

      if (response.statusCode == 200) {
        return ApiResponseParser.parseList<TermsListRequestDto>(
          response.data,
          TermsListRequestDto.fromJson,
        );
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: "서버 응답 오류: ${response.statusCode}",
      );
    } catch (e) {
      AppLogger.error('TermsListRequestService.requestTermsList 에러: $e');
      rethrow;
    }
  }
}
