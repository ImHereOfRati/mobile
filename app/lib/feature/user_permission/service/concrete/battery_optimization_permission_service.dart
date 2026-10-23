import 'dart:io' show Platform;

import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:permission_handler/permission_handler.dart';

/// 배터리 최적화 제외 설정을 관리하는 서비스.
///
/// Android 전용. iOS 는 배터리 최적화 개념이 OS 레벨에서 앱별 토글 형태로 존재하지
/// 않으므로 항상 [PermissionState.grantedAlways] 를 반환한다.
class BatteryOptimizationPermissionService
    implements PermissionServiceInterface {
  @override
  Future<PermissionState> checkPermissionStatus() async {
    if (!Platform.isAndroid) return PermissionState.grantedAlways;
    final status = await Permission.ignoreBatteryOptimizations.status;
    return _map(status);
  }

  @override
  Future<PermissionState> requestPermission() async {
    if (!Platform.isAndroid) return PermissionState.grantedAlways;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return _map(status);
  }

  @override
  Future<bool> isPermissionGranted() async {
    final status = await checkPermissionStatus();
    return status == PermissionState.grantedAlways;
  }

  PermissionState _map(PermissionStatus status) {
    if (status.isGranted) return PermissionState.grantedAlways;
    if (status.isPermanentlyDenied) return PermissionState.permanentlyDenied;
    if (status.isRestricted) return PermissionState.restricted;
    return PermissionState.denied;
  }
}
