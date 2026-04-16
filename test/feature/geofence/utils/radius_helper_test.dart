import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/geofence/utils/radius_helper.dart';

void main() {
  group('RadiusHelper 유틸리티 테스트', () {
    test('getRadiusInfoMessage는 250m에 대해 올바른 메시지를 반환해야 한다', () {
      // given
      const radius = 250;

      // when
      final message = RadiusHelper.getRadiusInfoMessage(radius);

      // then
      expect(message, '정확한 위치에서 알림을 보내드려요!');
    });

    test('getRadiusInfoMessage는 500m에 대해 올바른 메시지를 반환해야 한다', () {
      // given
      const radius = 500;

      // when
      final message = RadiusHelper.getRadiusInfoMessage(radius);

      // then
      expect(message, '적절한 범위에서 알림을 보내드려요!');
    });

    test('getRadiusInfoMessage는 1km에 대해 올바른 메시지를 반환해야 한다', () {
      // given
      const radius = 1000;

      // when
      final message = RadiusHelper.getRadiusInfoMessage(radius);

      // then
      expect(message, 'GPS가 정확하지 않아도 알람을 보낼 수 있어요!');
    });

    test('getRadiusInfoMessage는 지원하지 않는 반경에 대해 빈 문자열을 반환해야 한다', () {
      // given
      const unsupportedRadius = 750;

      // when
      final message = RadiusHelper.getRadiusInfoMessage(unsupportedRadius);

      // then
      expect(message, '');
    });

    test('supportedRadiusValues는 모든 지원 반경을 포함해야 한다', () {
      // when
      final supportedValues = RadiusHelper.supportedRadiusValues;

      // then
      expect(supportedValues, contains(250));
      expect(supportedValues, contains(500));
      expect(supportedValues, contains(1000));
      expect(supportedValues.length, 3);
    });

    test('상수 값들이 올바르게 정의되어 있어야 한다', () {
      // then
      expect(RadiusHelper.radius250m, 250);
      expect(RadiusHelper.radius500m, 500);
      expect(RadiusHelper.radius1km, 1000);
    });
  });
}
