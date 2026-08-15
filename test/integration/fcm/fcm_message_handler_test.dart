import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/integration/fcm/fcm_message_handler.dart';

void main() {
  group('composeForegroundNotificationMessage', () {
    test('body가 있으면 title과 body를 함께 보여준다', () {
      expect(
        composeForegroundNotificationMessage(
          '새로운 친구 요청',
          '홍길동님이 친구 요청을 보냈습니다.',
        ),
        '새로운 친구 요청\n홍길동님이 친구 요청을 보냈습니다.',
      );
    });

    test('body가 없으면 title만 반환한다', () {
      expect(
        composeForegroundNotificationMessage('ImHere 알림', ''),
        'ImHere 알림',
      );
    });
  });

  group('extractNotificationPath', () {
    test('서버 type 계약으로 친구 요청 화면을 결정한다', () {
      final path = extractNotificationPath({'type': 'FRIEND_REQUEST_RECEIVED'});

      expect(path, '/friend/requests');
    });

    test('서버 type 계약으로 알림함 화면을 결정한다', () {
      final path = extractNotificationPath({'type': 'ARRIVAL'});

      expect(path, '/record/notifications');
    });

    test('약관 변경 알림은 약관 관리 화면으로 이동한다', () {
      final path = extractNotificationPath({'type': 'TERMS_UPDATE_NOTICE'});

      expect(path, '/setting/agreements');
    });

    test('type이 없으면 null을 반환한다', () {
      final path = extractNotificationPath({'path': '/record/notifications'});

      expect(path, isNull);
    });
  });
}
