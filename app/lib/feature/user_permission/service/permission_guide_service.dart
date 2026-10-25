import 'dart:io' show Platform;

import 'package:iamhere/feature/user_permission/model/app_permission.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/locate_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

/// 앱 사용 권한 네 가지를 한 곳에서 확인하고 요청한다.
class PermissionGuideService {
  final LocatePermissionService _location;
  final PermissionServiceInterface _notification;
  final PermissionServiceInterface _batteryOptimization;
  final PermissionServiceInterface _contacts;
  final bool _isAndroid;
  final bool _notificationAvailable;
  final Future<bool> Function() _openSettings;

  PermissionGuideService({
    required LocatePermissionService location,
    required PermissionServiceInterface notification,
    required PermissionServiceInterface batteryOptimization,
    required PermissionServiceInterface contacts,
    bool? isAndroid,
    bool notificationAvailable = true,
    Future<bool> Function()? openSettings,
  }) : _location = location,
       _notification = notification,
       _batteryOptimization = batteryOptimization,
       _contacts = contacts,
       _isAndroid = isAndroid ?? Platform.isAndroid,
       _notificationAvailable = notificationAvailable,
       _openSettings = openSettings ?? handler.openAppSettings;

  bool get isAndroid => _isAndroid;

  /// 안내에 보여 줄 권한. 배터리 최적화 제외는 Android에만 있다.
  List<AppPermission> get permissions => [
    if (_notificationAvailable) AppPermission.notification,
    AppPermission.locationAlways,
    if (_isAndroid) AppPermission.batteryOptimization,
    AppPermission.contacts,
  ];

  Future<PermissionState> check(AppPermission permission) =>
      switch (permission) {
        AppPermission.notification => _notification.checkPermissionStatus(),
        AppPermission.locationAlways => _location.checkPermissionStatus(),
        AppPermission.batteryOptimization =>
          _batteryOptimization.checkPermissionStatus(),
        AppPermission.contacts => _contacts.checkPermissionStatus(),
      };

  Future<PermissionState> request(AppPermission permission) =>
      switch (permission) {
        AppPermission.notification => _notification.requestPermission(),
        AppPermission.locationAlways => _location.requestAlwaysPermission(),
        AppPermission.batteryOptimization =>
          _batteryOptimization.requestPermission(),
        AppPermission.contacts => _contacts.requestPermission(),
      };

  /// 안내할 권한이 모두 허용돼 있는지 확인한다.
  Future<bool> areAllGranted() async {
    for (final permission in permissions) {
      if (!isGranted(permission, await check(permission))) return false;
    }
    return true;
  }

  Future<bool> openSettings() => _openSettings();

  /// 위치는 '항상 허용'이어야 자동 전송이 되므로 '앱 사용 중'만으로는 부족하다.
  static bool isGranted(AppPermission permission, PermissionState state) {
    if (permission == AppPermission.locationAlways) {
      return state == PermissionState.grantedAlways;
    }
    return state == PermissionState.grantedAlways ||
        state == PermissionState.grantedWhenInUse;
  }
}
