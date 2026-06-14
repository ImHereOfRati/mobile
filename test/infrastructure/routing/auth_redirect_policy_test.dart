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
        requestedUri: Uri.parse(AppRoutes.record),
      );

      expect(result, '${AppRoutes.auth}?redirect=%2Frecord');
    });

    test('비인증 사용자가 auth 경로에 있으면 redirect하지 않는다', () {
      final result = policy.resolve(
        authState: AuthState.unauthenticated,
        matchedLocation: AppRoutes.auth,
        requestedUri: Uri.parse(AppRoutes.auth),
      );

      expect(result, isNull);
    });

    test('pending 사용자는 terms 경로 외에는 terms로 redirect한다 (redirect 파라미터 포함)', () {
      final result = policy.resolve(
        authState: AuthState.pending,
        matchedLocation: AppRoutes.geofence,
        requestedUri: Uri.parse(AppRoutes.geofence),
      );

      expect(result, startsWith(AppRoutes.termsConsent));
      expect(result, contains('redirect='));
    });

    test('인증 사용자가 auth 경로에 있으면 geofence로 redirect한다', () {
      final result = policy.resolve(
        authState: AuthState.authenticated,
        matchedLocation: AppRoutes.auth,
        requestedUri: Uri.parse(AppRoutes.auth),
      );

      expect(result, AppRoutes.geofence);
    });

    test('inactive 사용자가 보호된 경로에 접근하면 /auth?reason=inactive 로 redirect', () {
      final result = policy.resolve(
        authState: AuthState.inactive,
        matchedLocation: AppRoutes.geofence,
        requestedUri: Uri.parse(AppRoutes.geofence),
      );

      expect(result, '${AppRoutes.auth}?reason=inactive');
    });

    test('inactive 사용자가 이미 /auth 에 있으면 redirect 없음', () {
      final result = policy.resolve(
        authState: AuthState.inactive,
        matchedLocation: AppRoutes.auth,
        requestedUri: Uri.parse(AppRoutes.auth),
      );

      expect(result, isNull);
    });

    test('pending 사용자가 termsConsent 에 있으면 redirect 없음', () {
      final result = policy.resolve(
        authState: AuthState.pending,
        matchedLocation: AppRoutes.termsConsent,
        requestedUri: Uri.parse(AppRoutes.termsConsent),
      );

      expect(result, isNull);
    });

    test('인증 사용자가 auth 접근 시 redirect 파라미터가 있으면 해당 경로로 이동', () {
      final result = policy.resolve(
        authState: AuthState.authenticated,
        matchedLocation: AppRoutes.auth,
        requestedUri: Uri.parse('${AppRoutes.auth}?redirect=/record'),
      );

      expect(result, '/record');
    });

    test('null authState 는 비인증으로 처리하여 auth redirect', () {
      final result = policy.resolve(
        authState: null,
        matchedLocation: AppRoutes.geofence,
        requestedUri: Uri.parse(AppRoutes.geofence),
      );

      expect(result, contains(AppRoutes.auth));
    });
  });
}
