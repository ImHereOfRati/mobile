import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/terms/model/repository/terms_repository.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';

class _RepositoryFake extends Fake implements TermsRepository {
  _RepositoryFake(this.terms, this.history);

  final List<Term> terms;
  final List<AgreementHistoryEntry> history;
  final withdrawn = <int>[];

  @override
  Future<List<Term>> fetchActiveTerms() async => terms;

  @override
  Future<List<AgreementHistoryEntry>> fetchAgreementHistory() async => history;

  @override
  Future<void> withdraw(int termId) async => withdrawn.add(termId);
}

Term _term(
  int id, {
  bool required = true,
  String effectiveDate = '2026-01-01',
}) => Term(
  id: id,
  title: '약관$id',
  content: '',
  type: 'SERVICE',
  isRequired: required,
  version: 1,
  effectiveDate: effectiveDate,
);

AgreementHistoryEntry _entry(int termId, AgreementAction action, String at) =>
    AgreementHistoryEntry(termId: termId, action: action, occurredAt: at);

void main() {
  test(
    'uses the most recent history entry regardless of server order',
    () async {
      final service = TermsService(
        _RepositoryFake(
          [_term(1, required: false)],
          [
            _entry(1, AgreementAction.withdraw, '2026-03-01T00:00:00'),
            _entry(1, AgreementAction.consent, '2026-02-01T00:00:00'),
          ],
        ),
      );

      final agreements = await service.loadAgreements();

      expect(agreements.single.isAgreed, isFalse);
    },
  );

  test(
    'asks for renewal only when the term took effect after consent',
    () async {
      final service = TermsService(
        _RepositoryFake(
          [_term(1, effectiveDate: '2026-05-01'), _term(2)],
          [
            _entry(1, AgreementAction.consent, '2026-02-01T00:00:00'),
            _entry(2, AgreementAction.consent, '2026-02-01T00:00:00'),
          ],
        ),
      );

      final agreements = await service.loadAgreements();

      expect(agreements[0].needsRenewal, isTrue);
      expect(agreements[1].needsRenewal, isFalse);
    },
  );

  test('does not withdraw a required term', () async {
    final repository = _RepositoryFake([_term(1)], const []);
    final service = TermsService(repository);

    expect(() => service.withdraw(_term(1)), throwsStateError);
    expect(repository.withdrawn, isEmpty);

    await service.withdraw(_term(2, required: false));
    expect(repository.withdrawn, [2]);
  });
}
