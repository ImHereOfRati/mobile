import 'package:iamhere/feature/user_permission/model/permission_state.dart';

class SettingViewModelState {
  final PermissionState pushPermission;
  final PermissionState locationPermission;
  final PermissionState contactPermission;
  final String appVersion;

  SettingViewModelState({
    this.pushPermission = PermissionState.denied,
    this.locationPermission = PermissionState.denied,
    this.contactPermission = PermissionState.denied,
    this.appVersion = '',
  });

  SettingViewModelState copyWith({
    PermissionState? pushPermission,
    PermissionState? locationPermission,
    PermissionState? contactPermission,
    String? appVersion,
  }) {
    return SettingViewModelState(
      pushPermission: pushPermission ?? this.pushPermission,
      locationPermission: locationPermission ?? this.locationPermission,
      contactPermission: contactPermission ?? this.contactPermission,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
