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
        autoSendReady: false,
        matchedLocation: AppRoutes.record,
        requestedUri: Uri.parse(AppRoutes.record),
      );

      expect(result, '${AppRoutes.auth}?redirect=%2Frecord');
    });

    test('비인증 사용자가 auth 경로에 있으면 redirect하지 않는다', () {
      final result = policy.resolve(
        authState: AuthState.unauthenticated,
        autoSendReady: false,
        matchedLocation: AppRoutes.auth,
        requestedUri: Uri.parse(AppRoutes.auth),
      );

      expect(result, isNull);
    });

    test('pending 사용자는 terms 경로 외에는 terms로 redirect한다 (redirect 파라미터 포함)', () {
      final result = policy.resolve(
        authState: AuthState.pending,
        autoSendReady: false,
        matchedLocation: AppRoutes.geofence,
        requestedUri: Uri.parse(AppRoutes.geofence),
      );

      expect(result, startsWith(AppRoutes.termsConsent));
      expect(result, contains('redirect='));
    });

    test('인증 사용자가 준비 안 된 상태면 userPermission 으로 redirect한다', () {
      final result = policy.resolve(
        authState: AuthState.authenticated,
        autoSendReady: false,
        matchedLocation: AppRoutes.auth,
        requestedUri: Uri.parse(AppRoutes.auth),
      );

      expect(result, '${AppRoutes.userPermission}?redirect=%2Fauth');
    });

    test('inactive 사용자가 보호된 경로에 접근하면 /auth?reason=inactive 로 redirect', () {
      final result = policy.resolve(
        authState: AuthState.inactive,
        autoSendReady: false,
        matchedLocation: AppRoutes.geofence,
        requestedUri: Uri.parse(AppRoutes.geofence),
      );

      expect(result, '${AppRoutes.auth}?reason=inactive');
    });

    test('inactive 사용자가 이미 /auth 에 있으면 redirect 없음', () {
      final result = policy.resolve(
        authState: AuthState.inactive,
        autoSendReady: false,
        matchedLocation: AppRoutes.auth,
        requestedUri: Uri.parse(AppRoutes.auth),
      );

      expect(result, isNull);
    });

    test('pending 사용자가 termsConsent 에 있으면 redirect 없음', () {
      final result = policy.resolve(
        authState: AuthState.pending,
        autoSendReady: false,
        matchedLocation: AppRoutes.termsConsent,
        requestedUri: Uri.parse(AppRoutes.termsConsent),
      );

      expect(result, isNull);
    });

    test('인증 사용자가 auth 접근 시 redirect 파라미터가 있으면 해당 경로로 이동', () {
      final result = policy.resolve(
        authState: AuthState.authenticated,
        autoSendReady: true,
        matchedLocation: AppRoutes.auth,
        requestedUri: Uri.parse('${AppRoutes.auth}?redirect=/record'),
      );

      expect(result, '/record');
    });

    test('null authState 는 비인증으로 처리하여 auth redirect', () {
      final result = policy.resolve(
        authState: null,
        autoSendReady: false,
        matchedLocation: AppRoutes.geofence,
        requestedUri: Uri.parse(AppRoutes.geofence),
      );

      expect(result, contains(AppRoutes.auth));
    });

    test('준비가 완료되면 userPermission 에서 redirect 로 복귀한다', () {
      final result = policy.resolve(
        authState: AuthState.authenticated,
        autoSendReady: true,
        matchedLocation: AppRoutes.userPermission,
        requestedUri: Uri.parse('${AppRoutes.userPermission}?redirect=/record'),
      );

      expect(result, '/record');
    });

    test('준비가 완료된 인증 사용자는 userPermission 이 아니면 redirect 되지 않는다', () {
      final result = policy.resolve(
        authState: AuthState.authenticated,
        autoSendReady: true,
        matchedLocation: AppRoutes.geofence,
        requestedUri: Uri.parse(AppRoutes.geofence),
      );

      expect(result, isNull);
    });

    test('준비가 안 된 상태에서도 권한 안내 화면은 열 수 있다', () {
      final result = policy.resolve(
        authState: AuthState.authenticated,
        autoSendReady: false,
        matchedLocation: AppRoutes.locationPermissionGuide,
        requestedUri: Uri.parse(AppRoutes.locationPermissionGuide),
      );

      expect(result, isNull);
    });
  });
}
