import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/core/dio/properties/http_status_code.dart';
import 'package:injectable/injectable.dart';

import 'dto/fcm_token.dart';

/// FCM 토큰을 서버에 전송하는 Repository
@lazySingleton
class FcmTokenRepository {
  final Dio _dio;

  FcmTokenRepository(this._dio);

  Future<bool> enrollFcmToken(String fcmToken) async {
    try {
      final request = FcmToken.fromCurrentPlatform(fcmToken: fcmToken);

      final response = await _dio.post(
        ApiConfig.fcmEnrollPath,
        data: request.toJson(),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == HttpStatusCode.ok) {
        debugPrint('FCM token enrolled successfully');
        return true;
      } else {
        debugPrint('Failed to message FCM token: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      debugPrint('DioException while enrolling FCM token: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      return false;
    } catch (e) {
      debugPrint('Error enrolling FCM token: $e');
      return false;
    }
  }
}
