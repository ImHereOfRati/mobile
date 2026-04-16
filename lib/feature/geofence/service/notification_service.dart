import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:injectable/injectable.dart';

/// FCM notification service - separate from SMS
@lazySingleton
class NotificationService {
  final Dio _dio;
  final String _sendToMeApiPath = '/api/v1/notification/self';

  NotificationService(this._dio);

  /// Send FCM notification to current user
  Future<Result<void>> sendNotificationToMe() async {
    try {
      final response = await _dio.post(_sendToMeApiPath);

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('FCM notification sent successfully');
        return Success(null);
      } else {
        log('FCM notification failed: ${response.statusCode}');
        return Failure('FCM notification failed: ${response.statusCode}');
      }
    } catch (e) {
      log('Error sending FCM notification: $e');
      return Failure('Error sending FCM notification: $e');
    }
  }
}
