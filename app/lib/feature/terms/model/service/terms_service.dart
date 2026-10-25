import 'package:iamhere/feature/terms/model/dto/agreement_history_entry.dart';
import 'package:iamhere/feature/terms/model/dto/term.dart';
import 'package:iamhere/feature/terms/model/repository/terms_repository.dart';
import 'package:injectable/injectable.dart';

export 'package:iamhere/feature/terms/model/dto/agreement_history_entry.dart';
export 'package:iamhere/feature/terms/model/dto/term.dart';

/// 약관 한 건과, 그 약관에 대한 사용자의 현재 동의 상태.
class TermAgreement {
  final Term term;
  final AgreementHistoryEntry? latest;

  const TermAgreement({required this.term, required this.latest});

  bool get isAgreed => latest?.isAgreed ?? false;

  /// 약관이 개정되면 시행일이 마지막 동의 시각보다 뒤로 간다. 그때는 기존
  /// 동의가 현재 약관에 대한 동의가 아니므로 재동의를 받아야 한다.
  bool get needsRenewal =>
      isAgreed && term.effectiveDate.compareTo(latest!.occurredAt) > 0;
}

@injectable
class TermsService {
  final TermsRepository _repository;

  TermsService(this._repository);

  Future<List<Term>> loadActiveTerms() => _repository.fetchActiveTerms();

  Future<List<TermAgreement>> loadAgreements() async {
    final results = await Future.wait([
      _repository.fetchActiveTerms(),
      _repository.fetchAgreementHistory(),
    ]);
    final terms = results[0] as List<Term>;
    final history = results[1] as List<AgreementHistoryEntry>;
    final latestByTerm = <int, AgreementHistoryEntry>{};
    for (final entry in history) {
      final current = latestByTerm[entry.termId];
      // 서버가 순서를 보장하지 않아 시각으로 직접 고른다.
      if (current == null ||
          entry.occurredAt.compareTo(current.occurredAt) > 0) {
        latestByTerm[entry.termId] = entry;
      }
    }
    return [
      for (final term in terms)
        TermAgreement(term: term, latest: latestByTerm[term.id]),
    ];
  }

  Future<void> consent(Term term) => _repository.consent(term.id);

  Future<void> consentToRenewal(Term term) =>
      _repository.consentToRenewal(term.id);

  Future<void> withdraw(Term term) {
    if (term.isRequired) {
      throw StateError('필수 약관은 철회할 수 없습니다.');
    }
    return _repository.withdraw(term.id);
  }
}
