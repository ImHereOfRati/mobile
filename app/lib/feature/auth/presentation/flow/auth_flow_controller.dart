import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/service/auth_login_coordinator.dart';
import 'package:iamhere/feature/auth/model/login_result.dart';
import 'package:iamhere/feature/auth/model/oauth_provider.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/terms/service/terms_service.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';

enum AuthFlowStatus { idle, loading, authenticated, pending, failure }

class AuthFlowState {
  final AuthFlowStatus status;
  final String? errorMessage;

  const AuthFlowState(this.status, {this.errorMessage});

  const AuthFlowState.idle() : this(AuthFlowStatus.idle);
}

class AuthFlowDependencies {
  final AuthLoginCoordinator coordinator;
  final AuthService authService;

  const AuthFlowDependencies(this.coordinator, this.authService);
}

final authFlowControllerProvider =
    StateNotifierProvider.family<
      AuthFlowController,
      AuthFlowState,
      AuthFlowDependencies
    >(
      (ref, dependencies) => AuthFlowController(
        dependencies.coordinator,
        dependencies.authService,
      ),
    );

final activeTermsProvider = FutureProvider.family<List<Term>, TermsService>(
  (ref, termsService) => termsService.loadActiveTerms(),
);

class AuthFlowController extends StateNotifier<AuthFlowState> {
  final AuthLoginCoordinator _coordinator;
  final AuthService _authService;
  final AnalyticsReporter _analytics;

  AuthFlowController(
    this._coordinator,
    this._authService, {
    AnalyticsReporter? analytics,
  }) : _analytics = analytics ?? FirebaseAnalyticsReporter(),
       super(const AuthFlowState.idle());

  Future<AuthFlowStatus> signIn(OauthProvider provider) async {
    state = const AuthFlowState(AuthFlowStatus.loading);
    try {
      final result = provider == OauthProvider.kakao
          ? await _coordinator.handleKakaoLogin()
          : await _coordinator.handleGoogleLogin();
      if (!mounted) return AuthFlowStatus.failure;
      return result.when(
        success: (memberState) {
          final next = memberState == MemberState.existingUser
              ? AuthFlowStatus.authenticated
              : AuthFlowStatus.pending;
          state = AuthFlowState(next);
          return next;
        },
        failure: (message) {
          state = AuthFlowState(AuthFlowStatus.failure, errorMessage: message);
          return AuthFlowStatus.failure;
        },
      );
    } catch (error, stack) {
      AppLogger.error('Login failed unexpectedly', error, stack);
      if (mounted) {
        state = const AuthFlowState(
          AuthFlowStatus.failure,
          errorMessage: '로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.',
        );
      }
      return AuthFlowStatus.failure;
    }
  }

  Future<bool> acceptTerms(Iterable<Term> terms, Set<int> agreedIds) async {
    state = const AuthFlowState(AuthFlowStatus.loading);
    try {
      await _authService.activateWithTerms(
        terms
            .map(
              (term) => <String, Object?>{
                'id': term.id,
                'agreed': agreedIds.contains(term.id),
              },
            )
            .toList(growable: false),
      );
      final requiredCount = terms.where((term) => term.isRequired).length;
      final optionalCount = terms.length - requiredCount;
      try {
        await _analytics.logEvent(
          'terms_accepted',
          parameters: {
            'required_count': requiredCount,
            'optional_count': optionalCount,
          },
        );
      } catch (error, stack) {
        AppLogger.error('Terms analytics failed', error, stack);
      }
      if (!mounted) return false;
      state = const AuthFlowState(AuthFlowStatus.authenticated);
      return true;
    } catch (error, stack) {
      AppLogger.error('Terms activation failed', error, stack);
      if (mounted) {
        state = const AuthFlowState(
          AuthFlowStatus.failure,
          errorMessage: '약관 동의를 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
        );
      }
      return false;
    }
  }
}
