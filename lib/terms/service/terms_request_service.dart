import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iamhere/shared/base/api_response/api_response.dart';
import 'package:iamhere/shared/infrastructure/dio/api_config.dart';
import 'package:iamhere/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/terms/service/dto/terms_version_response_dto.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TermsRequestService {
  final Dio _dio;

  TermsRequestService(this._dio);

  Future<APIResponse<PageResponse<TermsListRequestDto>>>
  requestTermsList() async {
    try {
      final response = await _dio.get(ApiConfig.termsListPath);

      if (response.statusCode == 200) {
        return APIResponse<PageResponse<TermsListRequestDto>>.fromJson(
          response.data,
          (json) => PageResponse<TermsListRequestDto>.fromJson(
            json as Map<String, dynamic>,
            (itemJson) =>
                TermsListRequestDto.fromJson(itemJson as Map<String, dynamic>),
          ),
        );
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: "서버 응답 오류: ${response.statusCode}",
      );
    } catch (e) {
      debugPrint('TermsListRequestService.requestTermsList 에러: $e');
      rethrow;
    }
  }

  Future<APIResponse<TermsVersionResponseDto>> requestTermsDetail(
    int termDefinitionId,
  ) async {
    try {
      final path = ApiConfig.termsVersionPath(termDefinitionId.toString());
      final response = await _dio.get(path);

      if (response.statusCode == 200) {
        return APIResponse<TermsVersionResponseDto>.fromJson(
          response.data,
          (json) =>
              TermsVersionResponseDto.fromJson(json as Map<String, dynamic>),
        );
      }

      throw Exception("상세 조회 실패 (ID: $termDefinitionId)");
    } catch (e) {
      debugPrint('TermsListRequestService.requestTermsDetail 에러: $e');
      rethrow;
    }
  }
}
