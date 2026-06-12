import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

import 'dto/after_terms_agreement_auth_response_dto.dart';
import 'dto/terms_consent_request_dto.dart';

@lazySingleton
class TermsResponseService {
  static const String _allTermsConsentPath = '/api/auth/activation';

  final Dio _dio;

  TermsResponseService(this._dio);

  Future<ApiResponse<AfterTermsAgreementAuthResponseDto>>
  requestToAllAgreeAboutRequiredTerms(
    List<TermsConsentItemDto> consents,
  ) async {
    try {
      final body = TermsAllConsentRequestDto(consents: consents).toJson();
      final response = await _dio.post(
        _allTermsConsentPath,
        data: body,
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 200) {
        return ApiResponseParser.parseObject<
          AfterTermsAgreementAuthResponseDto
        >(response.data, AfterTermsAgreementAuthResponseDto.fromJson);
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
