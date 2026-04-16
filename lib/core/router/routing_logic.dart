import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/auth/model/auth_state.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';

/// 라우팅 플로우:
/// 1. 미인증 → /auth
/// 2. 인증 완료 + /auth 에 있을 경우 → /geofence (이미 로그인된 재방문 사용자)
/// 3. 나머지 온보딩 흐름은 명시적 navigation 으로 처리:
///    - 신규(201): auth → terms-consent → user-permission → geofence
///    - 기존(200): auth → geofence
///

//TODO : 현재 존재하는 문제 -> 만약 사용자가 약관 동의 페이지에서 나가는 경우, 그 어떤 경우에도 201 상태를 벗어날 수 없다.
// 해결 방법 1 : newUser 와 같은 값 역시 핸들링 한다.

class RouterLogic {
  static String? handleRedirect(Ref ref, GoRouterState state) {
    final authState = ref.read(authStateProvider);

    if (authState.isLoading) return null;
    if (authState.hasError) return null;

    return _decidePath(authState.asData?.value, state);
  }

  static String? _decidePath(AuthState? authState, GoRouterState state) {
    final isAuthenticated = authState == AuthState.authenticated;

    // 미인증: auth 페이지가 아닌 경우 auth 로 이동
    if (!isAuthenticated) {
      return state.matchedLocation == AppRoutes.auth ? null : AppRoutes.auth;
    }

    // 인증 완료 + auth 페이지에 머무는 경우 (재방문 사용자) → 메인으로
    if (state.matchedLocation == AppRoutes.auth) {
      return AppRoutes.geofence;
    }

    return null;
  }
}
