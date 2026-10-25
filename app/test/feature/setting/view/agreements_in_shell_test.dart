import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/setting/view/page/agreements_page.dart';
import 'package:iamhere/feature/setting/view/page/term_detail_page.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/shell/view/native_app_shell.dart';
import 'package:iamhere/theme/imhere_theme.dart';

class _TermsServiceFake extends Fake implements TermsService {
  final term = const Term(
    id: 1,
    title: '서비스 이용약관',
    content: '약관 내용',
    type: 'SERVICE',
    isRequired: true,
    version: 1,
    effectiveDate: '2026-01-01',
  );

  @override
  Future<List<TermAgreement>> loadAgreements() async => [
    TermAgreement(term: term, latest: null),
  ];

  @override
  Future<Term?> findTerm(int id) async => term;
}

void main() {
  late GoRouter router;

  Future<void> pumpShell(WidgetTester tester) async {
    final service = _TermsServiceFake();
    router = GoRouter(
      initialLocation: '/setting',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return NativeAppShell(
              page: NativeShellPage.fromLocation(state.uri.path),
              onNavigate: router.go,
              onBack: router.pop,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/setting',
              pageBuilder: (_, __) => NoTransitionPage(
                child: Center(
                  child: TextButton(
                    onPressed: () => router.go('/setting/agreements'),
                    child: const Text('열기'),
                  ),
                ),
              ),
              routes: [
                GoRoute(
                  path: 'agreements',
                  builder: (_, __) => AgreementsPage(termsService: service),
                  routes: [
                    GoRoute(
                      path: ':termId',
                      builder: (_, state) => TermDetailPage(
                        termsService: service,
                        termId: int.parse(state.pathParameters['termId']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: ImHereAppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'agreements and term detail keep the ImHere header in the shell',
    (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // 셸의 로고 헤더와 하단 네비게이션 아래에 약관 동의 관리가 보인다.
      expect(find.byType(NativeAppShell), findsOneWidget);
      expect(find.byType(ImHereAppHeader), findsOneWidget);
      expect(find.byType(ImHereNavigation), findsOneWidget);
      expect(find.byType(ImHereTopBar), findsNothing);
      expect(find.text('서비스 이용약관'), findsOneWidget);

      await tester.tap(find.text('약관 보기'));
      await tester.pumpAndSettle();

      expect(find.byType(ImHereAppHeader), findsOneWidget);
      expect(find.byType(ImHereNavigation), findsOneWidget);
      expect(find.byType(ImHereTopBar), findsNothing);
      expect(find.text('약관 내용'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('약관 보기'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('열기'), findsOneWidget);
    },
  );
}
