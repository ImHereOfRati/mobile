import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

/// 위치 권한 게이트 정책 객체.
/// View 가 권한 분기 로직을 직접 들고 있지 않도록 공통화한다.
class LocationPermissionGate {
  final PermissionServiceInterface _service;

  const LocationPermissionGate(this._service);

  /// 알림 생성에 필요한 최소 위치 권한을 확인하고, 거부 상태면 1회 요청한다.
  /// 사용 중 허용 이상이면 true.
  Future<bool> resolveForCreate() async {
    var status = await _service.checkPermissionStatus();
    if (status == PermissionState.denied) {
      status = await _service.requestPermission();
    }
    return status == PermissionState.grantedAlways ||
        status == PermissionState.grantedWhenInUse;
  }

  /// 자동 전송에 필요한 `항상 허용` 을 보장한다.
  /// 부족하면 자동 전송 준비 페이지를 열고, 완료되면 결과를 돌려준다.
  Future<bool> ensureAlways(BuildContext context) async {
    if (await _isAlways()) return true;
    if (!context.mounted) return false;

    final result = await context.push<bool>(AppRoutes.userPermission);
    if (!context.mounted) return false;
    if (result == true) return true;
    return _isAlways();
  }

  Future<bool> _isAlways() async =>
      await _service.checkPermissionStatus() == PermissionState.grantedAlways;
}
