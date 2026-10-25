import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/record/model/repository/geofence_record_local_repository.dart';
import 'package:iamhere/feature/setting/model/type/setting_status.dart';
import 'package:iamhere/feature/setting/model/service/setting_status_service_interface.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

@Injectable(as: SettingStatusServiceInterface)
class SettingStatusService implements SettingStatusServiceInterface {
  final PermissionServiceInterface _location;
  final PermissionServiceInterface _notification;
  final PermissionServiceInterface _batteryOptimization;
  final PermissionServiceInterface _contacts;
  final GeofenceRecordLocalRepository _records;

  SettingStatusService(
    @Named('location') this._location,
    @Named('fcmAlert') this._notification,
    @Named('batteryOptimization') this._batteryOptimization,
    @Named('friend') this._contacts,
    this._records,
  );

  @override
  Future<SettingStatus> load() async {
    final results = await Future.wait([
      _isGranted(SettingPermission.notification),
      _isGranted(SettingPermission.locationAlways),
      _isGranted(SettingPermission.batteryOptimization),
      _isGranted(SettingPermission.contacts),
      _lastDelivery(),
      _appVersion(),
    ]);
    return SettingStatus(
      permissions: {
        SettingPermission.notification: results[0] as bool,
        SettingPermission.locationAlways: results[1] as bool,
        SettingPermission.batteryOptimization: results[2] as bool,
        SettingPermission.contacts: results[3] as bool,
      },
      lastDelivery: results[4] as LastDelivery?,
      appVersion: results[5] as String?,
    );
  }

  @override
  Future<void> requestPermission(SettingPermission permission) async {
    await _service(permission).requestPermission();
  }

  @override
  Future<void> openAppSettings() async {
    if (!await permissions.openAppSettings()) {
      throw StateError('Unable to open app settings.');
    }
  }

  PermissionServiceInterface _service(SettingPermission permission) =>
      switch (permission) {
        SettingPermission.notification => _notification,
        SettingPermission.locationAlways => _location,
        SettingPermission.batteryOptimization => _batteryOptimization,
        SettingPermission.contacts => _contacts,
      };

  Future<bool> _isGranted(SettingPermission permission) async {
    final state = await _service(permission).checkPermissionStatus();
    if (permission == SettingPermission.locationAlways) {
      return state == PermissionState.grantedAlways;
    }
    return state == PermissionState.grantedAlways ||
        state == PermissionState.grantedWhenInUse;
  }

  Future<LastDelivery?> _lastDelivery() async {
    try {
      final records = await _records.findAllOrderByCreatedAtDesc();
      if (records.isEmpty) return null;
      final latest = records.first;
      return LastDelivery(
        geofenceName: latest.geofenceName,
        occurredAt: latest.createdAt,
      );
    } catch (error, stack) {
      AppLogger.error('Failed to load last delivery', error, stack);
      return null;
    }
  }

  Future<String?> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (error, stack) {
      AppLogger.error('Failed to load app info', error, stack);
      return null;
    }
  }
}
