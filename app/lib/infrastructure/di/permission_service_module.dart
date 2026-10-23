import 'package:iamhere/feature/user_permission/service/concrete/battery_optimization_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/concrete/contact_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/concrete/fcm_alert_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/concrete/locate_permission_service.dart';
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
