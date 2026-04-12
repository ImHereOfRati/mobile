import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/auth/service/auth_state_provider.dart';
import 'package:iamhere/user_permission/model/permission_item.dart';
import 'package:iamhere/user_permission/view_model/user_permission_view_model.dart';

/// 라우팅 플로우:
/// 1. 필수 권한 확인 → 권한 없으면 권한 요청 페이지로 이동
/// 2. 인증 상태 확인 → 미인증이면 로그인 페이지로 이동
/// 3. 온보딩 완료 후 메인 페이지(Geofence)로 이동
class RouterLogic {
  static const _permissionPage = '/user-permission';
  static const _authPage = '/auth';
  static const _geofencePage = '/geofence';

  static String? handleRedirect(Ref ref, GoRouterState state) {
    final permissionState = ref.read(userPermissionViewModelProvider);
    final authState = ref.read(authStateProvider);

    if (permissionState.isLoading || authState.isLoading) return null;
    if (permissionState.hasError || authState.hasError) return null;

    return _decidePath(
      permissionState.asData?.value,
      authState.asData?.value,
      state,
    );
  }

  static String? _decidePath(
    List<PermissionItem>? permissions,
    bool? isAuth,
    GoRouterState state,
  ) {
    // 1. 필수 권한 확인
    final permissionPath = _checkPermission(permissions, state);
    if (permissionPath != null) return permissionPath;

    // 2. 인증 상태 확인
    final authPath = _checkAuthState(isAuth, state);
    if (authPath != null) return authPath;

    return _routeToGeofencePage(state);
  }

  static String? _checkPermission(
    List<PermissionItem>? permissions,
    GoRouterState state,
  ) {
    final allRequiredPermissionsAreGranted =
        permissions?.where((e) => e.isRequired).every((e) => e.isGranted) ??
        false;

    if (!allRequiredPermissionsAreGranted) {
      return _permissionPage;
    }
    return null;
  }

  static String? _checkAuthState(bool? isLoggedIn, GoRouterState state) {
    if (!(isLoggedIn ?? false) && state.matchedLocation != _authPage) {
      return _authPage;
    }
    return null;
  }

  static String? _routeToGeofencePage(GoRouterState state) {
    final isOnboarding =
        state.matchedLocation == _permissionPage ||
        state.matchedLocation == _authPage;

    if (isOnboarding) return _geofencePage;
    return null;
  }
}
