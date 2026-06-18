import 'package:iamhere/feature/auth/service/auth_state.dart';

import 'app_routes.dart';

class AuthRedirectPolicy {
  const AuthRedirectPolicy();

  String? resolve({
    required AuthState? authState,
    required bool autoSendReady,
    required String matchedLocation,
    required Uri requestedUri,
  }) {
    final isPending = authState == AuthState.pending;
    final isInactive = authState == AuthState.inactive;
    final isAuthenticated = authState == AuthState.authenticated;

    if (!isAuthenticated && !isPending && !isInactive) {
      if (matchedLocation == AppRoutes.auth) return null;

      return Uri(
        path: AppRoutes.auth,
        queryParameters: {'redirect': requestedUri.toString()},
      ).toString();
    }

    if (isPending) {
      if (matchedLocation == AppRoutes.termsConsent) return null;
      return Uri(
        path: AppRoutes.termsConsent,
        queryParameters: {'redirect': requestedUri.toString()},
      ).toString();
    }

    if (isInactive) {
      if (matchedLocation == AppRoutes.auth) return null;
      return Uri(
        path: AppRoutes.auth,
        queryParameters: {'reason': 'inactive'},
      ).toString();
    }

    if (!autoSendReady) {
      if (matchedLocation == AppRoutes.userPermission ||
          matchedLocation == AppRoutes.locationPermissionGuide ||
          matchedLocation == AppRoutes.batteryOptimizationGuide) {
        return null;
      }

      return Uri(
        path: AppRoutes.userPermission,
        queryParameters: {'redirect': requestedUri.toString()},
      ).toString();
    }

    if (matchedLocation == AppRoutes.userPermission) {
      final redirect = requestedUri.queryParameters['redirect'];
      if (redirect != null && redirect.startsWith('/')) {
        return redirect;
      }

      return AppRoutes.geofence;
    }

    if (matchedLocation == AppRoutes.locationPermissionGuide ||
        matchedLocation == AppRoutes.batteryOptimizationGuide) {
      return null;
    }

    if (matchedLocation == AppRoutes.auth ||
        matchedLocation == AppRoutes.termsConsent) {
      final redirect = requestedUri.queryParameters['redirect'];
      if (redirect != null && redirect.startsWith('/')) {
        return redirect;
      }

      return AppRoutes.geofence;
    }

    return null;
  }
}
