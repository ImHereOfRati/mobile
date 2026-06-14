import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/integration/fcm/fcm_message_handler.dart';

void main() {
  group('extractNotificationPath', () {
    test('top-level path 를 우선 반환한다', () {
      final path = extractNotificationPath({
        'path': '/record/send-history',
        'extraData': {'path': '/friend/requests'},
      });

      expect(path, '/record/send-history');
    });

    test('extraData map 안의 path 를 읽는다', () {
      final path = extractNotificationPath({
        'extraData': {'path': '/friend/requests'},
      });

      expect(path, '/friend/requests');
    });

    test('extraData JSON string 안의 path 를 읽는다', () {
      final path = extractNotificationPath({
        'extraData': '{"body":"hello","path":"/record/notifications"}',
      });

      expect(path, '/record/notifications');
    });

    test('slash 로 시작하지 않는 path 는 무시한다', () {
      final path = extractNotificationPath({
        'extraData': {'path': 'record/send-history'},
      });

      expect(path, isNull);
    });

    test('path 가 없으면 null 을 반환한다', () {
      final path = extractNotificationPath({
        'extraData': {'body': 'hello'},
      });

      expect(path, isNull);
    });
  });
}
