import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/model/repeat_schedule.dart';

void main() {
  group('RepeatType', () {
    test('has correct display names', () {
      expect(RepeatType.none.displayName, '반복 안 함');
      expect(RepeatType.daily.displayName, '매일');
      expect(RepeatType.weekday.displayName, '평일');
      expect(RepeatType.weekend.displayName, '주말');
      expect(RepeatType.custom.displayName, '직접 설정');
    });
  });

  group('RepeatSchedule', () {
    test('default is none', () {
      final schedule = const RepeatSchedule();
      expect(schedule.type, RepeatType.none);
      expect(schedule.customDays, isNull);
    });

    test('copyWith updates type', () {
      final schedule = const RepeatSchedule(type: RepeatType.daily);
      final updated = schedule.copyWith(type: RepeatType.weekday);
      expect(updated.type, RepeatType.weekday);
    });

    test('customDaysBitmask encodes days correctly', () {
      // 0 (Sunday) | 1 (Monday) | 5 (Friday)
      final schedule = RepeatSchedule(
        type: RepeatType.custom,
        customDays: {0, 1, 5},
      );
      // 2^0 | 2^1 | 2^5 = 1 | 2 | 32 = 35
      expect(schedule.customDaysBitmask, 35);
    });

    test('fromBitmask decodes days correctly', () {
      // Bitmask: 35 = 2^0 | 2^1 | 2^5 = days 0, 1, 5
      final schedule = RepeatSchedule.fromBitmask(35);
      expect(schedule.type, RepeatType.custom);
      expect(schedule.customDays, {0, 1, 5});
    });

    test('fromBitmask with zero returns empty set', () {
      final schedule = RepeatSchedule.fromBitmask(0);
      expect(schedule.customDays, <int>{});
    });

    test('equality works correctly', () {
      final s1 = RepeatSchedule(
        type: RepeatType.custom,
        customDays: {0, 1, 5},
      );
      final s2 = RepeatSchedule(
        type: RepeatType.custom,
        customDays: {0, 1, 5},
      );
      final s3 = RepeatSchedule(
        type: RepeatType.custom,
        customDays: {0, 1},
      );
      expect(s1, s2);
      expect(s1, isNot(s3));
    });
  });
}
