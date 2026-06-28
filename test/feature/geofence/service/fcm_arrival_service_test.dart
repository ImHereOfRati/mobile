import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/feature/friend/service/fcm_notification_service.dart';
import 'package:iamhere/feature/geofence/service/fcm_arrival_service.dart';

class RecordingDio extends Fake implements Dio {
  String? capturedPath;
  Map<String, dynamic>? capturedData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
  }) async {
    capturedPath = path;
    capturedData = Map<String, dynamic>.from(data as Map);
    return Response<T>(
      data: {
        'imhereResponseCode': 'SUCCESS',
        'message': '알림이 발송 큐에 등록되었습니다.',
        'data': null,
      } as T,
      statusCode: 202,
      requestOptions: RequestOptions(path: path),
    );
  }
}

class FakeFcmNotificationService extends Fake implements FcmNotificationService {}

void main() {
  late RecordingDio mockDio;
  late FakeFcmNotificationService mockFcmNotificationService;
  late FcmArrivalService sut;

  setUp(() {
    mockDio = RecordingDio();
    mockFcmNotificationService = FakeFcmNotificationService();
    sut = FcmArrivalService(mockDio, mockFcmNotificationService);
  });

  test('도착 FCM payload 에 placeName 이 포함된다', () async {
    final result = await sut.sendGeofenceNotifications(
      receiverEmails: ['server@example.com'],
      body: '도착 본문',
      location: '우리집 (서울 강남구)',
      type: 'ARRIVAL',
    );

    expect(result, isA<Success<void>>());

    expect(mockDio.capturedPath, '/api/notifications');
    final payload = mockDio.capturedData!;
    expect(payload['extraData']['placeName'], '우리집 (서울 강남구)');
  });
}
