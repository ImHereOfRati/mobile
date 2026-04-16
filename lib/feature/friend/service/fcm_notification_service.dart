import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FcmNotificationService {
  final Dio _dio;

  FcmNotificationService({required Dio dio}) : _dio = dio;

  Future<bool> alertArrivalNotificationSuccessToMe(String fcmToken) async {
    Map<dynamic, dynamic> date = {};

    try {
      final response = await _dio.post(
        ApiConfig.fcmDeliveryResultPath,
        data: date,
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token enrolled successfully');
        return true;
      } else {
        debugPrint('Failed to enroll FCM token: ${response.statusCode}');
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
