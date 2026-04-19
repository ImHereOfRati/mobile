import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/feature/friend/service/dto/fcm_notification_request_dto.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:injectable/injectable.dart';

/// 서버 친구(ImHere 앱 유저)에게 목적지 도착 FCM 알림 발송
@lazySingleton
class FcmArrivalService {
  final Dio _dio;

  FcmArrivalService(this._dio);

  /// 여러 서버 친구에게 도착 알림 FCM 발송
  /// [body]는 이미 {location} 등 치환이 완료된 최종 본문이어야 한다.
  Future<Result<void>> sendArrivalNotifications({
    required List<String> receiverEmails,
    required String body,
  }) async {
    if (receiverEmails.isEmpty) {
      return Failure('No server recipients');
    }

    var allSuccess = true;
    for (final email in receiverEmails) {
      final result = await _sendOne(receiverEmail: email, body: body);
      if (result is Failure) {
        allSuccess = false;
      }
    }
    return allSuccess ? Success(null) : Failure('One or more FCM sends failed');
  }

  Future<Result<void>> _sendOne({
    required String receiverEmail,
    required String body,
  }) async {
    try {
      final dto = FcmNotificationRequestDto(
        receiverEmail: receiverEmail,
        type: 'ARRIVAL',
        body: body,
      );
      final response = await _dio.post(
        ApiConfig.fcmArrivalPath,
        data: dto.toJson(),
        options: ApiConfig.authOptions,
      );

      final ok = response.statusCode == 200 || response.statusCode == 201;
      if (!ok) {
        log(
          'FCM arrival failed ($receiverEmail): status=${response.statusCode}',
        );
        return Failure('FCM arrival failed: ${response.statusCode}');
      }
      return Success(null);
    } catch (e) {
      log('FCM arrival error ($receiverEmail): $e');
      return Failure('FCM arrival error: $e');
    }
  }
}
