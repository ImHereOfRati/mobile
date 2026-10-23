import 'package:iamhere/feature/user_permission/service/battery_optimization_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/contact_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/fcm_alert_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/locate_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:injectable/injectable.dart';

@module
abstract class PermissionServiceModule {
  @Named('location')
  PermissionServiceInterface get locationService => LocatePermissionService();

  @Named('fcmAlert')
  PermissionServiceInterface get fcmAlertService => FcmAlertPermissionService();

  @Named('friend')
  PermissionServiceInterface get contactService => ContactPermissionService();

  @Named('batteryOptimization')
  PermissionServiceInterface get batteryOptimizationService =>
      BatteryOptimizationPermissionService();
}
