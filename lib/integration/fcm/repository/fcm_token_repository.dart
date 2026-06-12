import 'package:dio/dio.dart';
import 'package:iamhere/infrastructure/network/properties/http_status_code.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

import 'dto/fcm_token.dart';

/// FCM 토큰을 서버에 전송하는 Repository
@lazySingleton
class FcmTokenRepository {
  static const String _fcmEnrollPath = '/api/fcm-tokens';

  final Dio _dio;

  FcmTokenRepository(this._dio);

  Future<bool> enrollFcmToken(String fcmToken) async {
    try {
      final request = FcmToken.fromCurrentPlatform(fcmToken: fcmToken);

      final response = await _dio.post(
        _fcmEnrollPath,
        data: request.toJson(),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == HttpStatusCode.ok ||
          response.statusCode == 201) {
        AppLogger.debug('FCM token enrolled successfully');
        return true;
      } else {
        AppLogger.error('Failed to message FCM token: ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      AppLogger.error('DioException while enrolling FCM token: ${e.message}');
      AppLogger.error('Response: ${e.response?.data}');
      return false;
    } catch (e) {
      AppLogger.error('Error enrolling FCM token: $e');
      return false;
    }
  }
}
