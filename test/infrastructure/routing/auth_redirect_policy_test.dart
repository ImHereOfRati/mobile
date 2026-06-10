import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/auth/service/auth_state.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:iamhere/infrastructure/routing/auth_redirect_policy.dart';

void main() {
  const policy = AuthRedirectPolicy();

  group('AuthRedirectPolicy', () {
    test('비인증 사용자가 보호된 경로로 접근하면 auth로 redirect한다', () {
      final result = policy.resolve(
        authState: AuthState.unauthenticated,
        matchedLocation: AppRoutes.record,
      );

      expect(result, AppRoutes.auth);
    });

    test('비인증 사용자가 auth 경로에 있으면 redirect하지 않는다', () {
      final result = policy.resolve(
        authState: AuthState.unauthenticated,
        matchedLocation: AppRoutes.auth,
      );

      expect(result, isNull);
    });

    test('인증 사용자가 auth 경로에 있으면 geofence로 redirect한다', () {
      final result = policy.resolve(
        authState: AuthState.authenticated,
        matchedLocation: AppRoutes.auth,
      );

      expect(result, AppRoutes.geofence);
    });
  });
}
