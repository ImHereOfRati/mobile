import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/model/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_draft.dart';
import 'package:iamhere/feature/geofence/model/type/geofence_repeat.dart';

void main() {
  test('수정 초안에 저장한 반복 요일을 복원한다', () {
    final draft = GeofenceDraft.fromEntity(
      GeofenceEntity(
        id: 1,
        name: '집',
        address: '서울',
        lat: 37,
        lng: 127,
        radius: 500,
        message: '도착했어요',
        contactIds: '[]',
        repeatType: 'custom',
        customDaysBitmask: 33, // 월요일과 토요일
      ),
      deviceContactIds: const {},
      serverRecipientKeys: const {},
    );

    expect(draft.repeat, GeofenceRepeat.custom);
    expect(draft.customDaysBitmask, 33);
    expect(
      draft.repeat.allows(DateTime(2026, 10, 26), draft.customDaysBitmask),
      isTrue,
    );
    expect(
      draft.repeat.allows(DateTime(2026, 10, 27), draft.customDaysBitmask),
      isFalse,
    );
  });

  test('요일 반복에서 요일을 고르지 않으면 저장할 수 없다', () {
    final draft = GeofenceDraft(repeat: GeofenceRepeat.custom);

    expect(draft.validate()[GeofenceField.repeatDays], isNotNull);
  });
}
