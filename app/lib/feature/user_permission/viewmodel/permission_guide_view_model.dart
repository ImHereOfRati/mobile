import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/user_permission/model/app_permission.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_guide_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_guide_view_model.g.dart';

/// 시스템 화면으로 넘어가기 전에 안내를 보여 주고, 계속할지 돌려준다.
typedef PermissionConfirm =
    Future<bool> Function(
      AppPermission permission, {
      required bool opensSettings,
    });

class PermissionGuideState {
  /// 확인을 마친 권한의 현재 상태. 아직 읽지 못한 권한은 들어 있지 않다.
  final Map<AppPermission, PermissionState> states;

  /// 요청을 한 번이라도 보낸 권한. 요청해도 달라지지 않으면 설정 앱으로 안내한다.
  final Set<AppPermission> attempted;
  final bool requestingAll;

  const PermissionGuideState({
    this.states = const {},
    this.attempted = const {},
    this.requestingAll = false,
  });

  PermissionGuideState copyWith({
    Map<AppPermission, PermissionState>? states,
    Set<AppPermission>? attempted,
    bool? requestingAll,
  }) => PermissionGuideState(
    states: states ?? this.states,
    attempted: attempted ?? this.attempted,
    requestingAll: requestingAll ?? this.requestingAll,
  );

  bool get loaded => states.isNotEmpty;

  bool isGranted(AppPermission permission) {
    final state = states[permission];
    return state != null && PermissionGuideService.isGranted(permission, state);
  }
}

@riverpod
class PermissionGuideViewModel extends _$PermissionGuideViewModel {
  late PermissionGuideService _service;

  @override
  PermissionGuideState build(PermissionGuideService service) {
    _service = service;
    return const PermissionGuideState();
  }

  List<AppPermission> get permissions => _service.permissions;

  bool get allGranted => permissions.every(state.isGranted);

  Future<void> refresh() async {
    final next = <AppPermission, PermissionState>{};
    for (final permission in permissions) {
      next[permission] = await _service.check(permission);
    }
    if (ref.mounted) state = state.copyWith(states: next);
  }

  /// 권한 하나를 요청한다. 이미 한 번 요청했는데도 허용되지 않으면 설정 앱을 연다.
  ///
  /// 시스템 화면으로 넘어가기 전에 [confirm]으로 무엇을 해야 하는지 알려 주고,
  /// 사용자가 확인했을 때만 이동한다.
  Future<void> request(
    AppPermission permission, {
    required PermissionConfirm confirm,
  }) async {
    final opensSettings = _opensSettings(permission);
    if (!await confirm(permission, opensSettings: opensSettings)) return;
    if (opensSettings) {
      await _service.openSettings();
    } else {
      await _requestOnce(permission);
    }
  }

  /// 허용되지 않은 권한을 순서대로 한 번에 요청한다.
  ///
  /// 설정 앱을 열어야 하는 권한은 중간에 앱을 벗어나 흐름이 끊기므로 건너뛰고,
  /// 해당 카드에서 따로 안내한다. [confirm]에서 거절하면 그 권한만 건너뛴다.
  Future<void> requestAll({required PermissionConfirm confirm}) async {
    if (state.requestingAll) return;
    state = state.copyWith(requestingAll: true);
    try {
      for (final permission in permissions) {
        if (state.isGranted(permission) || _opensSettings(permission)) continue;
        if (!await confirm(permission, opensSettings: false)) continue;
        await _requestOnce(permission);
        if (!ref.mounted) return;
      }
    } finally {
      if (ref.mounted) state = state.copyWith(requestingAll: false);
    }
  }

  bool _opensSettings(AppPermission permission) =>
      state.states[permission] == PermissionState.permanentlyDenied ||
      (state.attempted.contains(permission) && !state.isGranted(permission));

  Future<void> _requestOnce(AppPermission permission) async {
    PermissionState result;
    try {
      result = await _service.request(permission);
    } catch (error, stack) {
      AppLogger.error('Permission request failed: $permission', error, stack);
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      states: {...state.states, permission: result},
      attempted: {...state.attempted, permission},
    );
  }
}
