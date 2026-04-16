import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'setting_view_model_state.dart';

part 'setting_view_model.g.dart';

@riverpod
class SettingViewModel extends _$SettingViewModel {
  late final PermissionServiceInterface _fcmService;
  late final PermissionServiceInterface _locationService;

  @override
  Future<SettingViewModelState> build() async {
    _fcmService = ref.watch(fcmAlertPermissionServiceProvider);
    _locationService = ref.watch(locationPermissionServiceProvider);

    return _fetchInitialState();
  }

  Future<SettingViewModelState> _fetchInitialState() async {
    final push = await _fcmService.checkPermissionStatus();
    final location = await _locationService.checkPermissionStatus();

    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    final versionString = buildNumber.isEmpty
        ? 'v$version'
        : 'v$version+$buildNumber';

    return SettingViewModelState(
      pushPermission: push,
      locationPermission: location,
      appVersion: versionString,
    );
  }

  Future<void> refreshPermissions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInitialState());
  }
}
