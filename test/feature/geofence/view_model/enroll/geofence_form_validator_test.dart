import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/view_model/contact.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_area_info.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_basic_info.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_enroll_form_state.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_form_validator.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_status_info.dart';

GeofenceEnrollFormState _buildState({
  required List<Recipient> recipients,
  required String name,
  required String address,
  String message = '',
  EventType eventType = EventType.arrival,
}) {
  return GeofenceEnrollFormState(
    basic: GeofenceBasicInfo(
      name: name,
      address: address,
      message: message,
      eventType: eventType,
    ),
    area: const GeofenceAreaInfo(location: NLatLng(37.5, 127.0), radius: '500'),
    status: GeofenceStatusInfo(recipients: recipients),
  );
}

void main() {
  test('blocks SMS-only payloads over 45 chars', () {
    final state = _buildState(
      recipients: [
        LocalRecipient(Contact(id: 1, name: '연락처', number: '01012345678')),
      ],
      name: '우리집',
      address: '서울특별시 강남구 삼성동',
      message:
          '이 문장은 SMS 본문이 45자를 훨씬 넘도록 충분히 길게 작성된 테스트용 메시지입니다.',
    );

    final result = GeofenceFormValidator.validate(state);

    expect(result.isValid, isFalse);
    expect(result.errorMessage, contains('45'));
  });

  test('allows valid SMS payloads when only FCM recipients are selected', () {
    final state = _buildState(
      recipients: const [
        ServerRecipient(
          friendRelationshipId: 'rel-1',
          friendEmail: 'friend@example.com',
          friendAlias: '친구',
        ),
      ],
      name: '아주아주긴장소이름테스트',
      address: '서울특별시 강남구 삼성동',
    );

    final result = GeofenceFormValidator.validate(state);

    expect(result.isValid, isTrue);
  });
}
