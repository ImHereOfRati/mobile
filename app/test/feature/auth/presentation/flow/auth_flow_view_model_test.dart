import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/feature/auth/model/type/login_result.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:iamhere/feature/auth/viewmodel/sign_in_view_model.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';

class _CoordinatorFake extends Fake implements SocialLoginService {
  _CoordinatorFake(this.login);

  final Future<Result<MemberState>> Function() login;

  @override
  Future<Result<MemberState>> handleKakaoLogin() => login();

  @override
  Future<Result<MemberState>> handleGoogleLogin() => login();
}

class _AuthServiceFake extends Fake implements AuthService {
  _AuthServiceFake(this.activate);

  final Future<void> Function(List<Map<String, Object?>>) activate;

  @override
  Future<void> activateWithTerms(List<Map<String, Object?>> consents) =>
      activate(consents);
}

class _AnalyticsFake implements AnalyticsReporter {
  _AnalyticsFake({this.fail = false});

  final bool fail;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (fail) throw StateError('analytics unavailable');
  }

  @override
  Future<void> setConsent(bool granted) async {}
}

void main() {
  final terms = [
    const Term(
      id: 1,
      title: '필수 약관',
      content: '내용',
      type: 'SERVICE',
      isRequired: true,
      version: 1,
      effectiveDate: '2026-01-01',
    ),
    const Term(
      id: 2,
      title: '선택 약관',
      content: '내용',
      type: 'MARKETING',
      isRequired: false,
      version: 1,
      effectiveDate: '2026-01-01',
    ),
  ];

  test(
    'unexpected login errors leave loading and show a safe message',
    () async {
      final coordinator = _CoordinatorFake(
        () async => throw StateError('oauth secret'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        signInViewModelProvider(coordinator).notifier,
      );

      final result = await viewModel.signIn(OauthProvider.kakao);

      expect(result, SignInStatus.failure);
      expect(viewModel.state.status, SignInStatus.failure);
      expect(viewModel.state.errorMessage, contains('다시 시도'));
    },
  );

  test('analytics failure does not undo successful terms activation', () async {
    List<Map<String, Object?>>? submitted;
    final authService = _AuthServiceFake(
      (consents) async => submitted = consents,
    );
    final container = ProviderContainer(
      overrides: [
        authAnalyticsReporterProvider.overrideWith(
          (ref) => _AnalyticsFake(fail: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    final viewModel = container.read(
      termsAcceptanceViewModelProvider(authService).notifier,
    );

    final result = await viewModel.accept(terms, {1});

    expect(result, isTrue);
    expect(viewModel.state.status, TermsAcceptanceStatus.completed);
    expect(submitted, [
      {'id': 1, 'agreed': true},
      {'id': 2, 'agreed': false},
    ]);
  });

  test(
    'terms activation failure leaves loading and shows a safe message',
    () async {
      final authService = _AuthServiceFake(
        (_) async => throw StateError('server detail'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        termsAcceptanceViewModelProvider(authService).notifier,
      );

      final result = await viewModel.accept(terms, {1});

      expect(result, isFalse);
      expect(viewModel.state.status, TermsAcceptanceStatus.failure);
      expect(viewModel.state.errorMessage, contains('다시 시도'));
    },
  );
}
