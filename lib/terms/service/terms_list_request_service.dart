import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:iamhere/common/api_response/api_response.dart';
import 'package:iamhere/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/terms/service/terms_version_response.dart';

@lazySingleton
class TermsListRequestService {
  final Dio _dio;

  TermsListRequestService(this._dio);

  static const _basePath = '/api/user/terms';

  Future<APIResponse<PageResponse<TermsListRequestDto>>>
  requestTermsList() async {
    try {
      final response = await _dio.get(_basePath);

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

  Future<TermsVersionResponse> requestTermsDetail(int termDefinitionId) async {
    try {
      final path = '$_basePath/version/$termDefinitionId';
      final response = await _dio.get(path);

      if (response.statusCode == 200) {
        return TermsVersionResponse.fromJson(response.data);
      }

      throw Exception("상세 조회 실패 (ID: $termDefinitionId)");
    } catch (e) {
      debugPrint('TermsListRequestService.requestTermsDetail 에러: $e');
      rethrow;
    }
  }
}
