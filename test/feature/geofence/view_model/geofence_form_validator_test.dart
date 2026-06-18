import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/friend/view_model/contact.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_enroll_form_state.dart';
import 'package:iamhere/feature/geofence/view_model/enroll/geofence_form_validator.dart';

void main() {
  GeofenceEnrollFormState validState() => GeofenceEnrollFormState(
        basic: const GeofenceBasicInfo(name: '집', address: '서울 강남구'),
        area: const GeofenceAreaInfo(
          location: NLatLng(37.5665, 126.9780),
          radius: '500',
        ),
        status: GeofenceStatusInfo(
          recipients: [
            LocalRecipient(Contact(id: 1, name: '엄마', number: '01000000000')),
          ],
        ),
      );

  group('GeofenceFormValidator', () {
    test('SMS 본문이 45자 이하면 유효하다', () {
      final result = GeofenceFormValidator.validate(validState());
      expect(result.isValid, isTrue);
    });

    test('장소 이름이 비어 있으면 무효', () {
      final state = validState().copyWith(basic: const GeofenceBasicInfo());
      final result = GeofenceFormValidator.validate(state);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('장소 이름'));
    });

    test('위치 미선택이면 무효', () {
      final state = validState().copyWith(area: const GeofenceAreaInfo());
      final result = GeofenceFormValidator.validate(state);
      expect(result.isValid, isFalse);
    });

    test('잘못된 반경이면 무효', () {
      final state = validState().copyWith(
        area: const GeofenceAreaInfo(
          location: NLatLng(37.5665, 126.9780),
          radius: 'abc',
        ),
      );
      final result = GeofenceFormValidator.validate(state);
      expect(result.isValid, isFalse);
    });

    test('수신자가 없으면 무효', () {
      final state = validState().copyWith(status: const GeofenceStatusInfo());
      final result = GeofenceFormValidator.validate(state);
      expect(result.isValid, isFalse);
    });

    test('보낼 메시지가 길면 무효', () {
      final state = validState().copyWith(
        basic: const GeofenceBasicInfo(
          name: '아주아주긴장소이름테스트',
          address: '서울특별시 강남구 삼성동',
          message:
              '이 문장은 SMS 본문이 45자를 훌쩍 넘기도록 충분히 길게 작성된 테스트용 메시지입니다.',
        ),
      );

      final result = GeofenceFormValidator.validate(state);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('45'));
    });
  });
}
