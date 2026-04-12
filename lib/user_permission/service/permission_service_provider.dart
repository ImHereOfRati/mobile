import 'package:iamhere/shared/infrastructure/di/di_setup.dart';
import 'package:iamhere/user_permission/service/permission_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_service_provider.g.dart';

@riverpod
PermissionServiceInterface locationPermissionService(Ref ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'location');
}

@riverpod
PermissionServiceInterface contactPermissionService(Ref ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'contact');
}

@riverpod
PermissionServiceInterface fcmAlertPermissionService(Ref ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'fcmAlert');
}
