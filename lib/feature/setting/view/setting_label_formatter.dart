import 'dart:io' show Platform;

import 'package:iamhere/feature/user_permission/model/permission_state.dart';

class SettingLabelFormatter {
  const SettingLabelFormatter._();

  static String battery(PermissionState state) {
    if (!Platform.isAndroid) return '해당 없음';
    switch (state) {
      case PermissionState.grantedAlways:
        return '준비 완료';
      case PermissionState.permanentlyDenied:
        return '설정에서 변경 필요';
      case PermissionState.restricted:
        return '제한됨';
      case PermissionState.denied:
      case PermissionState.grantedWhenInUse:
        return '설정 필요';
      case PermissionState.serviceDisabled:
        return '상태 확인 필요';
    }
  }

  static String permission(PermissionState state, {bool toggle = false}) {
    if (toggle) {
      return (state == PermissionState.grantedAlways ||
              state == PermissionState.grantedWhenInUse)
          ? '켜짐'
          : '꺼짐';
    }

    switch (state) {
      case PermissionState.grantedAlways:
        return '항상 허용';
      case PermissionState.grantedWhenInUse:
        return '사용 중 허용';
      default:
        return '거부됨';
    }
  }
}
