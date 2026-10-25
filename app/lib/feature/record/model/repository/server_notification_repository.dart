import 'package:dio/dio.dart';
import 'package:iamhere/feature/record/model/dto/server_notification_dto.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ServerNotificationRepository {
  static const pageSize = 20;
  static const _path = '/api/notifications';

  final Dio _dio;

  ServerNotificationRepository(this._dio);

  static final _authenticated = Options(
    extra: const {'requiresAuthentication': true},
  );

  /// 서버는 목록만 주고 다음 쪽이 있는지는 알려 주지 않는다.
  Future<List<ServerNotificationDto>> fetch(int page) async {
    final response = await _dio.get(
      _path,
      queryParameters: {'page': page, 'size': pageSize},
      options: _authenticated,
    );
    final raw = response.data;
    if (raw is! Map<String, dynamic> || raw['data'] is! List) {
      throw StateError('알림 응답 형식이 올바르지 않습니다.');
    }
    return (raw['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(ServerNotificationDto.fromJson)
        .toList(growable: false);
  }

  Future<void> markAsRead(int id) async {
    await _dio.patch<void>('$_path/$id/read', options: _authenticated);
  }

  /// 서버는 요청을 큐에 넣고 202로 답한다. 성공 응답이 곧 전달 완료는 아니다.
  Future<void> send({
    required String type,
    required List<String> targetIds,
    String method = 'FCM',
    Map<String, String> extraData = const {},
  }) async {
    await _dio.post<void>(
      _path,
      data: {
        'extraData': extraData,
        'notificationMethod': method,
        'targetIds': targetIds,
        'type': type,
      },
      options: _authenticated,
    );
  }
}
