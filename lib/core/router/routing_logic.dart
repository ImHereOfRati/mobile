import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/auth/model/auth_state.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';

class RouterLogic {
  static String? handleRedirect(Ref ref, GoRouterState state) {
    final authState = ref.read(authStateProvider);

    if (authState.isLoading) return null;
    if (authState.hasError) return null;

    return _decidePath(authState.asData?.value, state);
  }

  static String? _decidePath(AuthState? authState, GoRouterState state) {
    final isAuthenticated = authState == AuthState.authenticated;

    if (!isAuthenticated) {
      return state.matchedLocation == AppRoutes.auth ? null : AppRoutes.auth;
    }

    if (state.matchedLocation == AppRoutes.auth) {
      return AppRoutes.geofence;
    }

    return null;
  }
}
