import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/shared/base/api_response/api_response.dart';
import 'package:iamhere/shared/util/app_logger.dart';
import 'package:injectable/injectable.dart';

import 'dto/after_terms_agreement_auth_response_dto.dart';
import 'dto/terms_consent_request_dto.dart';

@lazySingleton
class TermsResponseService {
  final Dio _dio;

  TermsResponseService(this._dio);

  Future<APIResponse<AfterTermsAgreementAuthResponseDto>>
  requestToAllAgreeAboutRequiredTerms(
    List<TermsConsentItemDto> consents,
  ) async {
    try {
      final body = TermsAllConsentRequestDto(consents: consents).toJson();
      final response = await _dio.post(
        ApiConfig.allTermsConsentPath,
        data: body,
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        return APIResponse.fromJson(
          response.data,
          (json) => AfterTermsAgreementAuthResponseDto.fromJson(
            json as Map<String, dynamic>,
          ),
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

  Future<APIResponse<void>> requestToAgreeSingleTerm(
    int termDefinitionId,
  ) async {
    try {
      final response = await _dio.post(
        ApiConfig.termConsentPath(termDefinitionId.toString()),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        return APIResponse<void>.fromJson(response.data, (_) {});
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: "서버 응답 오류: ${response.statusCode}",
      );
    } catch (e) {
      AppLogger.error(
        'TermsResponseService.requestToAgreeSingleTerm 에러 (id=$termDefinitionId): $e',
      );
      rethrow;
    }
  }
}
