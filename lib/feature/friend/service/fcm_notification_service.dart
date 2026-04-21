import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:iamhere/core/dio/properties/api_config.dart';
import 'package:iamhere/core/dio/util/dio_handler.dart';
import 'package:iamhere/feature/friend/service/dto/fcm_notification_request_dto.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FcmNotificationService with DioHandler {
  final Dio _dio;

  FcmNotificationService({required Dio dio}) : _dio = dio;

  /// 알림 정상 발송 결과를 본인에게 FCM으로 통보
  Future<Result<void>> notifyDeliveryResult({
    required String receiverEmail,
    required String type,
    required String body,
  }) async {
    return await safeApiCall(() async {
      final dto = FcmNotificationRequestDto(
        receiverEmail: receiverEmail,
        type: type,
        body: body,
      );

      final response = await _dio.post(
        ApiConfig.fcmDeliveryResultPath,
        data: dto.toJson(),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        debugPrint('Delivery result notification sent successfully');
        return Success(null);
      } else {
        debugPrint('Failed to send delivery result: ${response.statusCode}');
        return Failure('Failed to send delivery result: ${response.statusCode}');
      }
    });
  }

  /// 일반 알림 FCM 발송 (친구 요청 등)
  Future<Result<void>> sendFcmNotification({
    required String receiverEmail,
    required String type,
    required String body,
  }) async {
    return await safeApiCall(() async {
      final dto = FcmNotificationRequestDto(
        receiverEmail: receiverEmail,
        type: type,
        body: body,
      );

      final response = await _dio.post(
        ApiConfig.fcmNotificationPath,
        data: dto.toJson(),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        debugPrint('FCM notification sent successfully');
        return Success(null);
      } else {
        debugPrint('Failed to send FCM notification: ${response.statusCode}');
        return Failure('Failed to send FCM notification: ${response.statusCode}');
      }
    });
  }

  /// 위치 수신 대상자 선정 알림 (앱 사용자 대상)
  Future<Result<void>> notifyLocationTarget({
    required String receiverEmail,
    required String type,
    required String body,
  }) async {
    return await safeApiCall(() async {
      final dto = FcmNotificationRequestDto(
        receiverEmail: receiverEmail,
        type: type,
        body: body,
      );

      final response = await _dio.post(
        ApiConfig.fcmLocationTargetPath,
        data: dto.toJson(),
        options: ApiConfig.authOptions,
      );

      if (response.statusCode == 200) {
        debugPrint('Location target notification sent successfully');
        return Success(null);
      } else {
        debugPrint(
          'Failed to send location target notification: ${response.statusCode}',
        );
        return Failure(
          'Failed to send location target notification: ${response.statusCode}',
        );
      }
    });
  }
}
