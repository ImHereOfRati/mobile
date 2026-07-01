import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/integration/fcm/fcm_notification_policy.dart';

void main() {
  group('resolveFcmChannelId', () {
    test('도착/출발 알림은 critical 채널을 사용한다', () {
      expect(resolveFcmChannelId('ARRIVAL'), criticalChannelId);
      expect(resolveFcmChannelId('ARRIVAL_CONFIRMATION'), criticalChannelId);
      expect(resolveFcmChannelId('DEPARTURE'), criticalChannelId);
    });

    test('친구 요청/위치 대상은 high 채널을 사용한다', () {
      expect(resolveFcmChannelId('FRIEND_REQUEST_RECEIVED'), highChannelId);
      expect(resolveFcmChannelId('LOCATION_TARGET'), highChannelId);
    });

    test('친구 수락/발송 실패는 normal 채널을 사용한다', () {
      expect(resolveFcmChannelId('FRIEND_REQUEST_ACCEPTED'), normalChannelId);
      expect(resolveFcmChannelId('DELIVERY_FAILED_NOTICE'), normalChannelId);
    });

    test('공지/발송 결과는 silent 채널을 사용한다', () {
      expect(resolveFcmChannelId('TERMS_UPDATE_NOTICE'), silentChannelId);
      expect(resolveFcmChannelId('DELIVERY_RESULT_NOTICE'), silentChannelId);
    });

    test('알 수 없는 타입도 silent 채널로 떨어진다', () {
      expect(resolveFcmChannelId('UNKNOWN_TYPE'), silentChannelId);
      expect(resolveFcmChannelId(null), silentChannelId);
    });
  });
}
