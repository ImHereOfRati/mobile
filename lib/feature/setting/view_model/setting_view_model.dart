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
  late final PermissionServiceInterface _contactService;
  late final PermissionServiceInterface _batteryOptimizationService;

  @override
  Future<SettingViewModelState> build() async {
    _fcmService = ref.watch(fcmAlertPermissionServiceProvider);
    _locationService = ref.watch(locationPermissionServiceProvider);
    _contactService = ref.watch(contactPermissionServiceProvider);
    _batteryOptimizationService = ref.watch(
      batteryOptimizationPermissionServiceProvider,
    );

    return _fetchInitialState();
  }

  Future<SettingViewModelState> _fetchInitialState() async {
    final push = await _fcmService.checkPermissionStatus();
    final location = await _locationService.checkPermissionStatus();
    final contact = await _contactService.checkPermissionStatus();
    final battery = await _batteryOptimizationService.checkPermissionStatus();

    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;
    final versionString = buildNumber.isEmpty
        ? 'v$version'
        : 'v$version+$buildNumber';

    return SettingViewModelState(
      pushPermission: push,
      locationPermission: location,
      contactPermission: contact,
      batteryOptimizationPermission: battery,
      appVersion: versionString,
    );
  }

  Future<void> refreshPermissions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInitialState());
  }

  Future<void> requestPushPermission() async {
    final current = state.asData?.value;
    if (current == null) return;
    final next = await _fcmService.requestPermission();
    state = AsyncData(current.copyWith(pushPermission: next));
  }

  Future<void> requestLocationPermission() async {
    final current = state.asData?.value;
    if (current == null) return;
    final next = await _locationService.requestPermission();
    state = AsyncData(current.copyWith(locationPermission: next));
  }

  Future<void> requestContactPermission() async {
    final current = state.asData?.value;
    if (current == null) return;
    final next = await _contactService.requestPermission();
    state = AsyncData(current.copyWith(contactPermission: next));
  }

  Future<void> requestBatteryOptimizationPermission() async {
    final current = state.asData?.value;
    if (current == null) return;
    final next = await _batteryOptimizationService.requestPermission();
    state = AsyncData(
      current.copyWith(batteryOptimizationPermission: next),
    );
  }
}
