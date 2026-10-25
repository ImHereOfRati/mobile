import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/auth/presentation/flow/auth_flow_controller.dart';
import 'package:iamhere/feature/auth/presentation/page/terms_page.dart';
import 'package:iamhere/feature/auth/service/auth_login_coordinator.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/terms/service/terms_service.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:iamhere/theme/imhere_theme.dart';

class _CoordinatorFake extends Fake implements AuthLoginCoordinator {}

class _AuthServiceFake extends Fake implements AuthService {
  List<Map<String, Object?>>? submitted;

  @override
  Future<void> activateWithTerms(List<Map<String, Object?>> consents) async {
    submitted = consents;
  }
}

class _TermsServiceFake extends Fake implements TermsService {}

class _AnalyticsFake implements AnalyticsReporter {
  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> setConsent(bool granted) async {}
}

void main() {
  const terms = [
    Term(
      id: 1,
      title: '이용약관',
      content: '필수 약관 내용',
      type: 'SERVICE',
      isRequired: true,
    ),
    Term(
      id: 2,
      title: '마케팅 안내',
      content: '선택 약관 내용',
      type: 'MARKETING',
      isRequired: false,
    ),
  ];

  Future<void> pumpTermsPage(
    WidgetTester tester, {
    required _AuthServiceFake authService,
    required Future<List<Term>> Function() loadTerms,
    required VoidCallback onDone,
  }) async {
    final termsService = _TermsServiceFake();
    final dependencies = AuthFlowDependencies(_CoordinatorFake(), authService);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTermsProvider(termsService).overrideWith((ref) => loadTerms()),
          authFlowControllerProvider(dependencies).overrideWith(
            (ref) => AuthFlowController(
              dependencies.coordinator,
              dependencies.authService,
              analytics: _AnalyticsFake(),
            ),
          ),
        ],
        child: MaterialApp(
          theme: ImHereAppTheme.light,
          home: TermsPage(
            dependencies: dependencies,
            termsService: termsService,
            onDone: onDone,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'required agreement enables submission without optional consent',
    (tester) async {
      final authService = _AuthServiceFake();
      var completed = false;
      await pumpTermsPage(
        tester,
        authService: authService,
        loadTerms: () async => terms,
        onDone: () => completed = true,
      );

      final submit = find.widgetWithText(ImHereButton, '동의하고 계속하기');
      expect(tester.widget<ImHereButton>(submit).onPressed, isNull);
      expect(find.text('동의하지 않아도 서비스를 이용할 수 있어요.'), findsOneWidget);

      await tester.tap(find.text('필수 약관 모두 동의'));
      await tester.pump();
      expect(tester.widget<ImHereButton>(submit).onPressed, isNotNull);

      await tester.tap(submit);
      await tester.pump();
      await tester.pump();
      expect(completed, isTrue);
      expect(authService.submitted, [
        {'id': 1, 'agreed': true},
        {'id': 2, 'agreed': false},
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('load error offers retry without exposing the exception', (
    tester,
  ) async {
    var attempts = 0;
    await pumpTermsPage(
      tester,
      authService: _AuthServiceFake(),
      loadTerms: () async {
        attempts++;
        if (attempts == 1) throw StateError('internal server detail');
        return terms;
      },
      onDone: () {},
    );

    expect(find.text('약관을 불러오지 못했어요'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pump();
    await tester.pump();
    expect(find.text('약관을 확인해 주세요'), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
