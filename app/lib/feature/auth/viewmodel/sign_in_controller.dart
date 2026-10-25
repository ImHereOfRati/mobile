import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/model/type/login_result.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_controller.g.dart';

enum SignInStatus { idle, loading, authenticated, pending, failure }

class SignInState {
  final SignInStatus status;
  final String? errorMessage;

  const SignInState(this.status, {this.errorMessage});

  const SignInState.idle() : this(SignInStatus.idle);
}

@riverpod
class SignInController extends _$SignInController {
  late SocialLoginService _coordinator;

  @override
  SignInState build(SocialLoginService coordinator) {
    _coordinator = coordinator;
    return const SignInState.idle();
  }

  Future<SignInStatus> signIn(OauthProvider provider) async {
    state = const SignInState(SignInStatus.loading);
    try {
      final result = provider == OauthProvider.kakao
          ? await _coordinator.handleKakaoLogin()
          : await _coordinator.handleGoogleLogin();
      if (!ref.mounted) return SignInStatus.failure;
      return result.when(
        success: (memberState) {
          final next = memberState == MemberState.existingUser
              ? SignInStatus.authenticated
              : SignInStatus.pending;
          state = SignInState(next);
          return next;
        },
        failure: (message) {
          state = SignInState(SignInStatus.failure, errorMessage: message);
          return SignInStatus.failure;
        },
      );
    } catch (error, stack) {
      AppLogger.error('Login failed unexpectedly', error, stack);
      if (ref.mounted) {
        state = const SignInState(
          SignInStatus.failure,
          errorMessage: '로그인 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.',
        );
      }
      return SignInStatus.failure;
    }
  }
}
