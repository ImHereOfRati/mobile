import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/auth/model/auth_state.dart';
import 'package:iamhere/auth/service/auth_state_provider.dart';
import 'package:iamhere/router/app_routes.dart';
import 'package:iamhere/user_permission/model/permission_item.dart';
import 'package:iamhere/user_permission/view_model/user_permission_view_model.dart';

/// 라우팅 플로우:
/// 1. 필수 권한 없음 → /user-permission
/// 2. 미인증 → /auth
/// 3. 인증 완료 + 약관 동의 페이지 → 그대로 유지
/// 4. 인증 완료 + 온보딩 페이지에 있을 경우 → /geofence
class RouterLogic {
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
    AuthState? authState,
    GoRouterState state,
  ) {
    // 1. 필수 권한 확인
    final permissionPath = _checkPermission(permissions, state);
    if (permissionPath != null) return permissionPath;

    // 2. 인증 상태 확인
    final authPath = _checkAuthState(authState, state);
    if (authPath != null) return authPath;

    // 3. 약관 동의 페이지는 인증 후 자유롭게 체류 가능
    if (state.matchedLocation == AppRoutes.termsConsent) return null;

    // 4. 인증된 상태에서 온보딩 페이지에 있으면 메인으로 이동
    return _routeFromOnboarding(state);
  }

  static String? _checkPermission(
    List<PermissionItem>? permissions,
    GoRouterState state,
  ) {
    final allGranted =
        permissions?.where((e) => e.isRequired).every((e) => e.isGranted) ??
        false;

    if (!allGranted && state.matchedLocation != AppRoutes.userPermission) {
      return AppRoutes.userPermission;
    }
    return null;
  }

  static String? _checkAuthState(AuthState? authState, GoRouterState state) {
    if (authState != AuthState.authenticated &&
        state.matchedLocation != AppRoutes.auth) {
      return AppRoutes.auth;
    }
    return null;
  }

  static String? _routeFromOnboarding(GoRouterState state) {
    if (state.matchedLocation == AppRoutes.userPermission) {
      return AppRoutes.geofence;
    }
    return null;
  }
}
