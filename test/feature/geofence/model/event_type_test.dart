import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';

void main() {
  group('EventType', () {
    test('arrival has correct display name', () {
      expect(EventType.arrival.displayName, '도착');
    });

    test('departure has correct display name', () {
      expect(EventType.departure.displayName, '출발');
    });

    test('both has correct display name', () {
      expect(EventType.both.displayName, '도착/출발 모두');
    });

    test('messageTemplate for arrival', () {
      expect(
        EventType.arrival.messageTemplate,
        '안녕하세요! {location}에 도착했습니다.',
      );
    });

    test('messageTemplate for departure', () {
      expect(
        EventType.departure.messageTemplate,
        '안녕하세요! {location}에서 출발했습니다.',
      );
    });

    test('messageTemplate for both', () {
      expect(
        EventType.both.messageTemplate,
        '안녕하세요! {location}에 도착/출발했습니다.',
      );
    });
  });
}
