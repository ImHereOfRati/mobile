import 'package:iamhere/feature/auth/service/auth_state.dart';

import 'app_routes.dart';

class AuthRedirectPolicy {
  const AuthRedirectPolicy();

  String? resolve({
    required AuthState? authState,
    required String matchedLocation,
  }) {
    final isAuthenticated = authState == AuthState.authenticated;

    if (!isAuthenticated) {
      return matchedLocation == AppRoutes.auth ? null : AppRoutes.auth;
    }

    if (matchedLocation == AppRoutes.auth) {
      return AppRoutes.geofence;
    }

    return null;
  }
}
