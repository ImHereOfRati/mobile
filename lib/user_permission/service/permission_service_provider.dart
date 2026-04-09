import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:iamhere/user_permission/service/permission_service_interface.dart';

final locationPermissionServiceProvider = Provider<PermissionServiceInterface>((ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'location');
});

final contactPermissionServiceProvider = Provider<PermissionServiceInterface>((ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'contact');
});

final fcmAlertPermissionServiceProvider = Provider<PermissionServiceInterface>((ref) {
  return getIt<PermissionServiceInterface>(instanceName: 'fcmAlert');
});
