import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/auth/service/auth_login_coordinator.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/terms/service/terms_service.dart';

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

  AuthFlowController(this._coordinator, this._authService)
    : super(const AuthFlowState.idle());

  Future<AuthFlowStatus> signIn(OauthProvider provider) async {
    state = const AuthFlowState(AuthFlowStatus.loading);
    final result = provider == OauthProvider.kakao
        ? await _coordinator.handleKakaoLogin()
        : await _coordinator.handleGoogleLogin();
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
      state = const AuthFlowState(AuthFlowStatus.authenticated);
      return true;
    } catch (error) {
      state = AuthFlowState(
        AuthFlowStatus.failure,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
}
