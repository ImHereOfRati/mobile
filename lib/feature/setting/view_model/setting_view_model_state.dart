import 'package:iamhere/feature/user_permission/model/permission_state.dart';

class SettingViewModelState {
  final PermissionState pushPermission;
  final PermissionState locationPermission;
  final String appVersion;

  SettingViewModelState({
    this.pushPermission = PermissionState.denied,
    this.locationPermission = PermissionState.denied,
    this.appVersion = '',
  });

  SettingViewModelState copyWith({
    PermissionState? pushPermission,
    PermissionState? smsPermission,
    PermissionState? locationPermission,
    String? appVersion,
  }) {
    return SettingViewModelState(
      pushPermission: pushPermission ?? this.pushPermission,
      locationPermission: locationPermission ?? this.locationPermission,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
