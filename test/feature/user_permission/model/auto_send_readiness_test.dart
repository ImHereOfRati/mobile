import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';

void main() {
  group('AutoSendReadiness', () {
    test('all requirements satisfied results in ready state', () {
      const readiness = AutoSendReadiness(
        locationPermission: PermissionState.grantedAlways,
        batteryOptimizationPermission: PermissionState.grantedAlways,
      );

      expect(readiness.isReady, true);
      expect(readiness.remainingSteps, 0);
      expect(readiness.summaryTitle, '자동 전송 준비 완료');
    });

    test('when always location is missing it asks for location setup', () {
      const readiness = AutoSendReadiness(
        locationPermission: PermissionState.grantedWhenInUse,
        batteryOptimizationPermission: PermissionState.grantedAlways,
      );

      expect(readiness.isReady, false);
      expect(readiness.remainingSteps, 1);
      expect(
        readiness.summaryDescription,
        '이 설정을 해두지 않으면 자동 전송을 사용할 수 없어요.\n위치를 항상 허용으로 해주어야\n자동으로 알람 발송이 가능해요.',
      );
      expect(readiness.locationStatusLabel, '사용 중 허용');
    });

    test(
      'service disabled and battery missing count as two remaining steps',
      () {
        const readiness = AutoSendReadiness(
          locationPermission: PermissionState.serviceDisabled,
          batteryOptimizationPermission: PermissionState.denied,
        );

        expect(readiness.isReady, false);
        expect(readiness.remainingSteps, 2);
        expect(readiness.summaryTitle, '자동 알림 준비 2단계 남음');
        expect(readiness.locationStatusLabel, '위치 서비스 꺼짐');
        expect(readiness.batteryStatusLabel, '미적용');
      },
    );
  });
}
