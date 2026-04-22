import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service_provider.g.dart';

@riverpod
PermissionServiceInterface locationPermissionService(Ref ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'location');
}

@riverpod
PermissionServiceInterface contactPermissionService(Ref ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'friend');
}

@riverpod
PermissionServiceInterface fcmAlertPermissionService(Ref ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'fcmAlert');
}

@riverpod
PermissionServiceInterface batteryOptimizationPermissionService(Ref ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'batteryOptimization');
}

/// 배터리 최적화 제외 상태를 반응형으로 노출한다.
/// 설정 앱에서 복귀 후 `ref.invalidate(batteryOptimizationStatusProvider)` 로 재조회.
@riverpod
Future<PermissionState> batteryOptimizationStatus(Ref ref) async {
  final service = ref.watch(batteryOptimizationPermissionServiceProvider);
  return service.checkPermissionStatus();
}
