import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/feature/user_permission/view_model/show_permission_prep_provider.dart';

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
  /// 부족하면 자동 전송 준비 화면(overlay)을 표시하고, 복귀 후 다시 확인한다.
  Future<bool> ensureAlways(BuildContext context) async {
    if (await _isAlways()) return true;
    if (!context.mounted) return false;

    try {
      final container = ProviderScope.containerOf(context);
      container.read(showPermissionPrepProvider.notifier).show();

      // 권한이 충족될 때까지 대기 (최대 1분)
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (await _isAlways()) {
          container.read(showPermissionPrepProvider.notifier).hide();
          return true;
        }
      }

      // timeout 시 overlay 닫고 false 반환
      container.read(showPermissionPrepProvider.notifier).hide();
    } catch (e) {
      // ProviderScope 없으면 기본 처리
    }

    if (!context.mounted) return false;
    return _isAlways();
  }

  Future<bool> _isAlways() async =>
      await _service.checkPermissionStatus() == PermissionState.grantedAlways;
}
