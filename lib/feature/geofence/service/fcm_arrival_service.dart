import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/feature/friend/service/dto/fcm_notification_request_dto.dart';
import 'package:iamhere/feature/friend/service/fcm_notification_service.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:iamhere/shared/util/app_logger.dart';
import 'package:injectable/injectable.dart';

/// 서버 친구(ImHere 앱 유저)에게 목적지 도착 FCM 알림 발송
@lazySingleton
class FcmArrivalService {
  final Dio _dio;
  final FcmNotificationService _fcmNotificationService;
  final UserMeServiceInterface _userMeService;

  FcmArrivalService(
    this._dio,
    this._fcmNotificationService,
    this._userMeService,
  );

  /// 여러 서버 친구에게 도착 알림 FCM 발송
  /// [body]는 이미 {location} 등 치환이 완료된 최종 본문이어야 한다.
  /// [location]은 본인 알림용으로 사용된다.
  Future<Result<void>> sendArrivalNotifications({
    required List<String> receiverEmails,
    required String body,
    required String location,
  }) async {
    if (receiverEmails.isEmpty) {
      return Failure('No server recipients');
    }

    int successCount = 0;
    for (final email in receiverEmails) {
      final result = await _sendOne(receiverEmail: email, body: body);
      if (result is Success) {
        successCount++;
      }
    }

    final bool isSuccess = successCount > 0;

    if (isSuccess) {
      return Success(null);
    } else {
      return Failure('All FCM sends failed');
    }
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
        options: ApiConfig.authOptions.copyWith(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final ok = response.statusCode == 200 || response.statusCode == 201;
      if (!ok) {
        dev.log(
          'FCM arrival failed ($receiverEmail): status=${response.statusCode}',
        );
        return Failure('FCM arrival failed: ${response.statusCode}');
      }
      return Success(null);
    } catch (e) {
      dev.log('FCM arrival error ($receiverEmail): $e');
      return Failure('FCM arrival error: $e');
    }
  }

  /// FCM 발송 성공 후 본인에게 FCM으로 발송 결과 통보
  Future<void> notifyDeliveryResultToMe(String location) async {
    try {
      dev.log('!!!! BG_SELF_NOTIFY: Method Start');
      
      final myInfo = await _userMeService.fetchMyInfo().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw 'fetchMyInfo Timeout',
      );
      
      if (myInfo != null) {
        dev.log('!!!! BG_SELF_NOTIFY: Email found ${myInfo.userEmail}');
        final result = await _fcmNotificationService.notifyDeliveryResult(
          receiverEmail: myInfo.userEmail,
          type: 'ARRIVAL',
          body: '$location 도착 알림이 성공적으로 전송되었습니다.',
        );

        if (result is Success) {
          dev.log('!!!! BG_SELF_NOTIFY: POST Success');
        } else {
          dev.log('!!!! BG_SELF_NOTIFY: POST Failed: ${(result as Failure).message}');
        }
      } else {
        dev.log('!!!! BG_SELF_NOTIFY: myInfo is NULL');
      }
    } catch (e) {
      dev.log('!!!! BG_SELF_NOTIFY: Critical Error: $e');
    }
  }
}
