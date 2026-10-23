import 'package:geolocator/geolocator.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/shell/bridge/bridge_handler_registry.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

class PermissionBridgeHandlers {
  final PermissionServiceInterface location;
  final PermissionServiceInterface notification;
  final PermissionServiceInterface batteryOptimization;
  final PermissionServiceInterface contacts;
  final Future<bool> Function() _openSettings;
  final Future<bool> Function() _isLocationServiceEnabled;

  PermissionBridgeHandlers({
    required this.location,
    required this.notification,
    required this.batteryOptimization,
    required this.contacts,
    Future<bool> Function()? openSettings,
    Future<bool> Function()? isLocationServiceEnabled,
  }) : _openSettings = openSettings ?? permissions.openAppSettings,
       _isLocationServiceEnabled =
           isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled;

  Map<String, BridgeMethodHandler> build() => {
    'getPermissionStatus': _getPermissionStatus,
    'requestPermission': _requestPermission,
    'openAppSettings': (_) async {
      if (!await _openSettings()) {
        throw StateError('Unable to open app settings.');
      }
      return null;
    },
    'getAutoSendReadiness': (_) => _readiness(),
  };

  Future<Map<String, Object?>> _getPermissionStatus(Object? params) async {
    final type = _permissionType(params);
    return _result(type, await _service(type).checkPermissionStatus());
  }

  Future<Map<String, Object?>> _requestPermission(Object? params) async {
    final type = _permissionType(params);
    return _result(type, await _service(type).requestPermission());
  }

  Future<Map<String, Object?>> _readiness() async {
    final locationState = await location.checkPermissionStatus();
    final notificationState = await notification.checkPermissionStatus();
    final batteryState = await batteryOptimization.checkPermissionStatus();
    final locationAlways = locationState == PermissionState.grantedAlways;
    final locationService = await _isLocationServiceEnabled();
    final notificationGranted = _isGranted(notificationState);
    final batteryGranted = _isGranted(batteryState);
    final missing = <String>[
      if (!locationAlways) 'locationAlways',
      if (!notificationGranted) 'notification',
      if (!batteryGranted) 'batteryOptimization',
    ];
    return {
      'ready':
          locationAlways &&
          locationService &&
          notificationGranted &&
          batteryGranted,
      'locationAlways': locationAlways,
      'locationService': locationService,
      'notification': notificationGranted,
      'batteryOptimization': batteryGranted,
      'missing': missing,
    };
  }

  PermissionServiceInterface _service(String type) => switch (type) {
    'locationWhenInUse' || 'locationAlways' => location,
    'notification' => notification,
    'batteryOptimization' => batteryOptimization,
    'contacts' => contacts,
    _ => throw ArgumentError.value(type, 'permission'),
  };

  Map<String, Object?> _result(String type, PermissionState state) => {
    'permission': type,
    'status': _status(type, state),
  };

  static String _status(String type, PermissionState state) {
    if (type == 'locationAlways' && state == PermissionState.grantedWhenInUse) {
      return 'denied';
    }
    return switch (state) {
      PermissionState.grantedAlways ||
      PermissionState.grantedWhenInUse => 'granted',
      PermissionState.denied => 'denied',
      PermissionState.permanentlyDenied => 'permanentlyDenied',
      PermissionState.restricted => 'restricted',
      PermissionState.serviceDisabled => 'serviceDisabled',
    };
  }

  static bool _isGranted(PermissionState state) =>
      state == PermissionState.grantedAlways ||
      state == PermissionState.grantedWhenInUse;

  static String _permissionType(Object? params) {
    if (params is! Map || params['permission'] is! String) {
      throw const FormatException('Expected permission.');
    }
    return params['permission'] as String;
  }
}
