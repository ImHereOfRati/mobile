import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_agreement_notifier.g.dart';

/// State for tracking terms agreement
@riverpod
class TermsAgreementNotifier extends _$TermsAgreementNotifier {
  /// Maps termDefinitionId to agreement status
  final Map<int, bool> _agreedTerms = {};

  @override
  Map<int, bool> build() {
    return _agreedTerms;
  }

  /// Toggle agreement for a specific term
  void toggleAgreement(int termDefinitionId) {
    final current = _agreedTerms[termDefinitionId] ?? false;
    _agreedTerms[termDefinitionId] = !current;
    state = Map.from(_agreedTerms);
  }

  /// Check if a specific term is agreed
  bool isTermAgreed(int termDefinitionId) {
    return _agreedTerms[termDefinitionId] ?? false;
  }

  /// Check if all required terms are agreed
  /// Pass list of required term IDs
  bool allRequiredTermsAgreed(List<int> requiredTermIds) {
    return requiredTermIds.every((id) => _agreedTerms[id] ?? false);
  }

  /// Get all agreed term IDs
  List<int> getAgreedTermIds() {
    return _agreedTerms.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }

  /// Reset all agreements
  void reset() {
    _agreedTerms.clear();
    state = Map.from(_agreedTerms);
  }

  /// Set agreed terms from list of IDs
  void setAgreedTerms(List<int> termIds) {
    _agreedTerms.clear();
    for (final id in termIds) {
      _agreedTerms[id] = true;
    }
    state = Map.from(_agreedTerms);
  }
}
