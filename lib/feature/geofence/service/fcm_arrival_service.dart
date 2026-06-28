import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/feature/friend/service/dto/fcm_notification_request_dto.dart';
import 'package:iamhere/feature/friend/service/fcm_notification_service.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:injectable/injectable.dart';

/// 서버 친구(ImHere 앱 유저)에게 위치 이벤트 FCM 알림 발송
@lazySingleton
class FcmArrivalService {
  static const String _fcmArrivalPath = '/api/notifications';

  final Dio _dio;
  final FcmNotificationService _fcmNotificationService;

  FcmArrivalService(
    this._dio,
    this._fcmNotificationService,
  );

  /// 여러 서버 친구에게 위치 이벤트 FCM 발송
  /// [body]는 이미 {location} 등 치환이 완료된 최종 본문이어야 한다.
  /// [location]은 서버가 도착/출발 본문을 만들 때 필요한 placeName 으로도 사용된다.
  Future<Result<void>> sendGeofenceNotifications({
    required List<String> receiverEmails,
    required String body,
    required String location,
    required String type,
  }) async {
    if (receiverEmails.isEmpty) {
      return Failure('No server recipients');
    }

    int successCount = 0;
    for (final email in receiverEmails) {
      final result = await _sendOne(
        receiverEmail: email,
        body: body,
        location: location,
        type: type,
      );
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
    required String location,
    required String type,
  }) async {
    try {
      final dto = FcmNotificationRequestDto(
        notificationMethod: 'FCM',
        targetId: receiverEmail,
        type: type,
        extraData: {
          'body': body,
          'path': AppRoutes.recordNotifications,
          'placeName': location,
        },
      );
      final response = await _dio.post(
        _fcmArrivalPath,
        data: dto.toJson(),
        options: Options(extra: const {'requiresAuthentication': true})
            .copyWith(
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
      );

      final ok = response.statusCode == 202;
      if (!ok) {
        dev.log(
          'FCM geofence notify failed ($receiverEmail): status=${response.statusCode}',
        );
        return Failure('FCM geofence notify failed: ${response.statusCode}');
      }
      ApiResponseParser.parseVoid(response.data);
      return Success(null);
    } catch (e) {
      dev.log('FCM geofence notify error ($receiverEmail): $e');
      return Failure('FCM geofence notify error: $e');
    }
  }
}
