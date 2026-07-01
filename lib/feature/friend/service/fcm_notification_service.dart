import 'package:dio/dio.dart';
import 'package:iamhere/common/base/api_response/api_response_parser.dart';
import 'package:iamhere/feature/friend/service/dto/fcm_notification_request_dto.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FcmNotificationService {
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
    String? path,
  }) {
    return _send(
      path: _fcmDeliveryResultPath,
      receiverEmail: receiverEmail,
      type: type,
      body: body,
      routePath: path ?? AppRoutes.recordNotifications,
      label: 'delivery result',
    );
  }

  /// 일반 알림 FCM 발송 (친구 요청 등)
  Future<Result<void>> sendFcmNotification({
    required String receiverEmail,
    required String type,
    required String body,
    String? path,
  }) {
    return _send(
      path: _fcmNotificationPath,
      receiverEmail: receiverEmail,
      type: type,
      body: body,
      routePath: path,
      label: 'FCM notification',
    );
  }

  /// 위치 수신 대상자 선정 알림 (앱 사용자 대상)
  Future<Result<void>> notifyLocationTarget({
    required String receiverEmail,
    required String type,
    required String body,
    required String location,
    String? path,
  }) {
    return _send(
      path: _fcmLocationTargetPath,
      receiverEmail: receiverEmail,
      type: type,
      body: body,
      location: location,
      routePath: path,
      label: 'location target notification',
    );
  }

  Future<Result<void>> _send({
    required String path,
    required String receiverEmail,
    required String type,
    required String body,
    String? location,
    String? routePath,
    required String label,
  }) async {
    try {
      final dto = FcmNotificationRequestDto(
        notificationMethod: 'FCM',
        targetId: receiverEmail,
        type: type,
        extraData: {
          'body': body,
          if (location != null) 'placeName': location,
          if (routePath != null) 'path': routePath,
        },
      );

      final response = await _dio.post(
        path,
        data: dto.toJson(),
        options: Options(extra: const {'requiresAuthentication': true}),
      );

      if (response.statusCode == 202) {
        ApiResponseParser.parseVoid(response.data);
        AppLogger.debug('$label sent successfully');
        return Success(null);
      }
      AppLogger.error('Failed to send $label: ${response.statusCode}');
      return Failure('Failed to send $label: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('Failed to send $label: ${e.message}');
      return Failure('Failed to send $label: ${e.message}');
    }
  }
}
