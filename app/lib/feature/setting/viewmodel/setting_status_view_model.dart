import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/setting/model/type/setting_status.dart';
import 'package:iamhere/feature/setting/model/service/setting_status_service_interface.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setting_status_view_model.g.dart';

/// 권한 행을 눌렀을 때 화면이 이어서 해야 할 일.
enum PermissionTapOutcome {
  /// 백그라운드 위치 고지를 보여준 뒤 [SettingStatusViewModel.openAppSettings]를 부른다.
  needsLocationDisclosure,
  done,
  failed,
}

@riverpod
class SettingStatusViewModel extends _$SettingStatusViewModel {
  late SettingStatusServiceInterface _service;

  @override
  Future<SettingStatus> build(SettingStatusServiceInterface service) {
    _service = service;
    return service.load();
  }

  /// 로딩 화면으로 돌아가지 않고 이전 값을 유지한 채 다시 읽는다. 설정 앱에서
  /// 돌아왔을 때 호출한다.
  Future<void> refresh() async {
    try {
      final next = await _service.load();
      if (ref.mounted) state = AsyncData(next);
    } catch (error, stack) {
      AppLogger.error('Setting status refresh failed', error, stack);
    }
  }

  Future<PermissionTapOutcome> onPermissionTap(
    SettingPermission permission,
  ) async {
    final granted = state.value?.isGranted(permission) ?? false;
    if (permission == SettingPermission.locationAlways) {
      return PermissionTapOutcome.needsLocationDisclosure;
    }
    try {
      if (granted) {
        await _service.openAppSettings();
      } else {
        await _service.requestPermission(permission);
      }
      await refresh();
      return PermissionTapOutcome.done;
    } catch (error, stack) {
      AppLogger.error('Permission action failed', error, stack);
      return PermissionTapOutcome.failed;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      await _service.openAppSettings();
      return true;
    } catch (error, stack) {
      AppLogger.error('Opening app settings failed', error, stack);
      return false;
    }
  }
}
