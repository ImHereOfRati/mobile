import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/record/view/component/record_time_formatter.dart';

void main() {
  group('RecordTimeFormatter.formatActivityLabel', () {
    test('deliveryEventType=arrival → {location} 도착 감지', () {
      expect(
        RecordTimeFormatter.formatActivityLabel(
          locationName: '집',
          deliveryEventType: 'arrival',
        ),
        '집 도착 감지',
      );
    });

    test('deliveryEventType=departure → {location} 출발 감지', () {
      expect(
        RecordTimeFormatter.formatActivityLabel(
          locationName: '학교',
          deliveryEventType: 'departure',
        ),
        '학교 출발 감지',
      );
    });

    test('알 수 없는 타입 → {location} 감지', () {
      expect(
        RecordTimeFormatter.formatActivityLabel(
          locationName: '회사',
          deliveryEventType: 'unknown',
        ),
        '회사 감지',
      );
    });
  });

  group('RecordTimeFormatter.formatRecipients', () {
    test('빈 리스트 → "수신자"', () {
      expect(RecordTimeFormatter.formatRecipients('[]'), '수신자');
    });

    test('단일 수신자 → 이름 그대로', () {
      expect(RecordTimeFormatter.formatRecipients('["엄마"]'), '엄마');
    });

    test('복수 수신자 → "첫번째 외 N명"', () {
      expect(
        RecordTimeFormatter.formatRecipients('["엄마","아빠","누나"]'),
        '엄마 외 2명',
      );
    });

    test('잘못된 JSON → "수신자" 폴백', () {
      expect(RecordTimeFormatter.formatRecipients('invalid json'), '수신자');
    });
  });

  group('RecordTimeFormatter.formatRelativeTime', () {
    test('1분 미만 → "방금 전"', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(RecordTimeFormatter.formatRelativeTime(dt), '방금 전');
    });

    test('1시간 미만 → "N분 전"', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 5));
      expect(RecordTimeFormatter.formatRelativeTime(dt), '5분 전');
    });

    test('24시간 미만 → "N시간 전"', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      expect(RecordTimeFormatter.formatRelativeTime(dt), '3시간 전');
    });

    test('7일 미만 → "N일 전"', () {
      final dt = DateTime.now().subtract(const Duration(days: 2));
      expect(RecordTimeFormatter.formatRelativeTime(dt), '2일 전');
    });

    test('7일 이상 → "M월 D일"', () {
      final dt = DateTime(2026, 3, 5);
      expect(RecordTimeFormatter.formatRelativeTime(dt), '3월 5일');
    });
  });
}
