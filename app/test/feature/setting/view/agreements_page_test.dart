import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/setting/view/page/agreements_page.dart';
import 'package:iamhere/theme/imhere_theme.dart';

class _TermsServiceFake extends Fake implements TermsService {
  _TermsServiceFake(this.agreements);

  List<TermAgreement> agreements;
  final withdrawn = <int>[];

  @override
  Future<List<TermAgreement>> loadAgreements() async => agreements;

  @override
  Future<void> withdraw(Term term) async {
    withdrawn.add(term.id);
    agreements = [
      for (final item in agreements)
        item.term.id == term.id
            ? TermAgreement(
                term: item.term,
                latest: AgreementHistoryEntry(
                  termId: term.id,
                  action: AgreementAction.withdraw,
                  occurredAt: '2026-04-01T00:00:00',
                ),
              )
            : item,
    ];
  }
}

Term _term(int id, {required bool isRequired, String? effectiveDate}) => Term(
  id: id,
  title: '약관$id',
  content: '내용$id',
  type: 'SERVICE',
  isRequired: isRequired,
  version: 1,
  effectiveDate: effectiveDate ?? '2026-01-01',
);

AgreementHistoryEntry _consent(int termId) => AgreementHistoryEntry(
  termId: termId,
  action: AgreementAction.consent,
  occurredAt: '2026-02-01T00:00:00',
);

void main() {
  Future<void> pump(WidgetTester tester, TermsService service) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ImHereAppTheme.light,
          home: AgreementsPage(termsService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers one emphasized action per term state', (tester) async {
    final service = _TermsServiceFake([
      TermAgreement(term: _term(1, isRequired: true), latest: _consent(1)),
      TermAgreement(term: _term(2, isRequired: false), latest: null),
      TermAgreement(
        term: _term(3, isRequired: true, effectiveDate: '2026-05-01'),
        latest: _consent(3),
      ),
    ]);

    await pump(tester, service);

    expect(
      find.text('필수 약관은 서비스 이용에 필요해 철회할 수 없어요.\n회원 탈퇴로만 동의를 거둘 수 있어요.'),
      findsNWidgets(2),
    );
    expect(find.text('동의하기'), findsOneWidget);
    expect(find.text('개정 약관 재동의'), findsOneWidget);
    expect(find.text('재동의 필요'), findsOneWidget);
    expect(find.text('동의 철회'), findsNothing);
  });

  testWidgets('withdrawing an optional term asks for confirmation', (
    tester,
  ) async {
    final service = _TermsServiceFake([
      TermAgreement(term: _term(2, isRequired: false), latest: _consent(2)),
    ]);

    await pump(tester, service);
    await tester.tap(find.widgetWithText(ImHereButton, '동의 철회'));
    await tester.pumpAndSettle();
    expect(service.withdrawn, isEmpty);

    await tester.tap(find.widgetWithText(ImHereButton, '동의 철회').last);
    await tester.pumpAndSettle();

    expect(service.withdrawn, [2]);
    expect(find.text('동의 안 함'), findsOneWidget);
  });
}
