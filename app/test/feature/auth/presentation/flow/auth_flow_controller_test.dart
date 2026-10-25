import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/feature/auth/model/login_result.dart';
import 'package:iamhere/feature/auth/model/oauth_provider.dart';
import 'package:iamhere/feature/auth/presentation/flow/auth_flow_controller.dart';
import 'package:iamhere/feature/auth/service/auth_login_coordinator.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/terms/service/terms_service.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';

class _CoordinatorFake extends Fake implements AuthLoginCoordinator {
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
    ),
    const Term(
      id: 2,
      title: '선택 약관',
      content: '내용',
      type: 'MARKETING',
      isRequired: false,
    ),
  ];

  test(
    'unexpected login errors leave loading and show a safe message',
    () async {
      final controller = AuthFlowController(
        _CoordinatorFake(() async => throw StateError('oauth secret')),
        _AuthServiceFake((_) async {}),
        analytics: _AnalyticsFake(),
      );
      addTearDown(controller.dispose);

      final result = await controller.signIn(OauthProvider.kakao);

      expect(result, AuthFlowStatus.failure);
      expect(controller.state.status, AuthFlowStatus.failure);
      expect(controller.state.errorMessage, contains('다시 시도'));
    },
  );

  test('analytics failure does not undo successful terms activation', () async {
    List<Map<String, Object?>>? submitted;
    final controller = AuthFlowController(
      _CoordinatorFake(() async => Success(MemberState.existingUser)),
      _AuthServiceFake((consents) async => submitted = consents),
      analytics: _AnalyticsFake(fail: true),
    );
    addTearDown(controller.dispose);

    final result = await controller.acceptTerms(terms, {1});

    expect(result, isTrue);
    expect(controller.state.status, AuthFlowStatus.authenticated);
    expect(submitted, [
      {'id': 1, 'agreed': true},
      {'id': 2, 'agreed': false},
    ]);
  });

  test(
    'terms activation failure leaves loading and shows a safe message',
    () async {
      final controller = AuthFlowController(
        _CoordinatorFake(() async => Success(MemberState.existingUser)),
        _AuthServiceFake((_) async => throw StateError('server detail')),
        analytics: _AnalyticsFake(),
      );
      addTearDown(controller.dispose);

      final result = await controller.acceptTerms(terms, {1});

      expect(result, isFalse);
      expect(controller.state.status, AuthFlowStatus.failure);
      expect(controller.state.errorMessage, contains('다시 시도'));
    },
  );
}
