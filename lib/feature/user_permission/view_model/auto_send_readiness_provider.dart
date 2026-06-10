import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/geofence/view_model/main/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';

/// 위치 권한 + 배터리 최적화 상태를 합쳐 자동 전송 준비 상태로 노출한다.
/// 아직 로딩 중이면 보수적으로 denied 로 취급한다.
final autoSendReadinessProvider = Provider<AutoSendReadiness>((ref) {
  final location = ref.watch(geofenceViewModelProvider).maybeWhen(
        data: (status) => status,
        orElse: () => PermissionState.denied,
      );
  final battery = ref.watch(batteryOptimizationStatusProvider).maybeWhen(
        data: (status) => status,
        orElse: () => PermissionState.denied,
      );
  return AutoSendReadiness(
    locationPermission: location,
    batteryOptimizationPermission: battery,
  );
});
