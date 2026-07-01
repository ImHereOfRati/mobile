import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/feature/friend/service/fcm_notification_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'fcm_notification_service_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late FcmNotificationService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = FcmNotificationService(dio: mockDio);
  });

  test('FCM 알림은 스펙 payload와 202 응답을 사용해야 함', () async {
    when(
      mockDio.post(
        '/api/notifications',
        data: {
          'notificationMethod': 'FCM',
          'targetId': 'target@example.com',
          'type': 'FRIEND_REQUEST_RECEIVED',
          'extraData': {'body': '친구 요청이 왔습니다.'},
        },
        options: anyNamed('options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'imhereResponseCode': 'SUCCESS',
          'message': '알림이 발송 큐에 등록되었습니다.',
          'data': null,
        },
        statusCode: 202,
        requestOptions: RequestOptions(path: '/api/notifications'),
      ),
    );

    final result = await service.sendFcmNotification(
      receiverEmail: 'target@example.com',
      type: 'FRIEND_REQUEST_RECEIVED',
      body: '친구 요청이 왔습니다.',
    );

    expect(result, isA<Success<void>>());
  });

  test('위치 대상자 알림은 placeName 을 payload 에 포함해야 함', () async {
    when(
      mockDio.post(
        '/api/notifications',
        data: {
          'notificationMethod': 'FCM',
          'targetId': 'target@example.com',
          'type': 'LOCATION_TARGET',
          'extraData': {
            'body': '위치 알림 대상자로 등록되었습니다.',
            'placeName': '우리집 (서울 강남구)',
          },
        },
        options: anyNamed('options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        data: {
          'imhereResponseCode': 'SUCCESS',
          'message': '알림이 발송 큐에 등록되었습니다.',
          'data': null,
        },
        statusCode: 202,
        requestOptions: RequestOptions(path: '/api/notifications'),
      ),
    );

    final result = await service.notifyLocationTarget(
      receiverEmail: 'target@example.com',
      type: 'LOCATION_TARGET',
      body: '위치 알림 대상자로 등록되었습니다.',
      location: '우리집 (서울 강남구)',
    );

    expect(result, isA<Success<void>>());
  });
}
