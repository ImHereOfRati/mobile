import 'package:iamhere/feature/user_permission/model/permission_state.dart';

enum AutoSendReadinessLevel { ready, needsAttention }

class AutoSendReadiness {
  final PermissionState locationPermission;
  final PermissionState batteryOptimizationPermission;

  const AutoSendReadiness({
    required this.locationPermission,
    required this.batteryOptimizationPermission,
  });

  bool get isLocationServiceDisabled =>
      locationPermission == PermissionState.serviceDisabled;

  bool get needsAlwaysLocation =>
      locationPermission != PermissionState.grantedAlways;

  bool get needsBatteryOptimization =>
      batteryOptimizationPermission != PermissionState.grantedAlways;

  bool get isReady =>
      !isLocationServiceDisabled &&
      !needsAlwaysLocation &&
      !needsBatteryOptimization;

  int get remainingSteps {
    if (isReady) return 0;

    var count = 0;
    if (isLocationServiceDisabled || needsAlwaysLocation) {
      count += 1;
    }
    if (needsBatteryOptimization) {
      count += 1;
    }
    return count;
  }

  AutoSendReadinessLevel get level => isReady
      ? AutoSendReadinessLevel.ready
      : AutoSendReadinessLevel.needsAttention;

  String get summaryTitle {
    if (isReady) {
      return '자동 전송 준비 완료';
    }
    return '자동 알림 준비 $remainingSteps단계 남음';
  }

  String get summaryDescription {
    const requiredNote = '이 설정을 해두지 않으면 자동 전송을 사용할 수 없어요.';

    if (isLocationServiceDisabled) {
      return '$requiredNote\n기기의 위치 서비스를 켜면 도착 알림이 현재 위치를 확인할 수 있어요.';
    }
    if (needsAlwaysLocation) {
      return '$requiredNote\n위치를 항상 허용으로 해주어야\n자동으로 알람 발송이 가능해요.';
    }
    if (needsBatteryOptimization) {
      return '$requiredNote\n앱이 닫혀 있어도 자동 전송이 끊기지 않게 배터리 최적화 제외가 필요해요.';
    }
    return '도착 알림이 자동으로 전송될 준비를 마쳤어요.';
  }



  String get locationStatusLabel {
    if (isLocationServiceDisabled) return '위치 서비스 꺼짐';
    if (locationPermission == PermissionState.grantedAlways) return '항상 허용';
    if (locationPermission == PermissionState.grantedWhenInUse) {
      return '사용 중 허용';
    }
    if (locationPermission == PermissionState.permanentlyDenied) return '설정 필요';
    if (locationPermission == PermissionState.restricted) return '제한됨';
    return '허용 안 됨';
  }

  String get batteryStatusLabel {
    if (batteryOptimizationPermission == PermissionState.grantedAlways) {
      return '제외 완료';
    }
    if (batteryOptimizationPermission == PermissionState.permanentlyDenied) {
      return '설정 필요';
    }
    if (batteryOptimizationPermission == PermissionState.restricted) {
      return '제한됨';
    }
    return '미적용';
  }
}
