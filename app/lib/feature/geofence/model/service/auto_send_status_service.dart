import 'package:geolocator/geolocator.dart';
import 'package:iamhere/feature/user_permission/model/app_permission.dart';
import 'package:iamhere/feature/user_permission/service/permission_guide_service.dart';

/// 자동 전송이 실제로 동작할 수 있는 상태인지.
class AutoSendStatus {
  final bool locationServiceEnabled;

  /// 자동 전송에 필요한데 아직 허용되지 않은 권한 수.
  final int missingPermissions;

  const AutoSendStatus({
    required this.locationServiceEnabled,
    required this.missingPermissions,
  });

  bool get ready => locationServiceEnabled && missingPermissions == 0;
}

/// 기기 GPS와 권한을 읽어 자동 전송 준비 상태를 만든다.
class AutoSendStatusService {
  final PermissionGuideService _permissions;
  final Future<bool> Function() _isLocationServiceEnabled;

  AutoSendStatusService(
    this._permissions, {
    Future<bool> Function()? isLocationServiceEnabled,
  }) : _isLocationServiceEnabled =
           isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled;

  Future<AutoSendStatus> load() async {
    var missing = 0;
    for (final permission in _permissions.permissions) {
      // 연락처는 친구 목록용이라 자동 전송에는 필요하지 않다.
      if (permission == AppPermission.contacts) continue;
      final state = await _permissions.check(permission);
      if (!PermissionGuideService.isGranted(permission, state)) missing++;
    }
    return AutoSendStatus(
      locationServiceEnabled: await _isLocationServiceEnabled(),
      missingPermissions: missing,
    );
  }
}
