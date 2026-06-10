import 'package:dio/dio.dart';
import 'package:iamhere/infrastructure/network/util/dio_handler.dart';
import 'package:iamhere/feature/friend/service/dto/fcm_notification_request_dto.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FcmNotificationService with DioHandler {
  static const String _fcmNotificationPath = '/api/notifications';
  static const String _fcmDeliveryResultPath = '/api/notifications';
  static const String _fcmLocationTargetPath = '/api/notifications';

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
        _fcmDeliveryResultPath,
        data: dto.toJson(),
        options: Options(extra: const {'requiresAuth': true}),
      );

      if (response.statusCode == 200) {
        AppLogger.debug('Delivery result notification sent successfully');
        return Success(null);
      } else {
        AppLogger.error('Failed to send delivery result: ${response.statusCode}');
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
        _fcmNotificationPath,
        data: dto.toJson(),
        options: Options(extra: const {'requiresAuth': true}),
      );

      if (response.statusCode == 200) {
        AppLogger.debug('FCM notification sent successfully');
        return Success(null);
      } else {
        AppLogger.error('Failed to send FCM notification: ${response.statusCode}');
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
        _fcmLocationTargetPath,
        data: dto.toJson(),
        options: Options(extra: const {'requiresAuth': true}),
      );

      if (response.statusCode == 200) {
        AppLogger.debug('Location target notification sent successfully');
        return Success(null);
      } else {
        AppLogger.error(
          'Failed to send location target notification: ${response.statusCode}',
        );
        return Failure(
          'Failed to send location target notification: ${response.statusCode}',
        );
      }
    });
  }
}
