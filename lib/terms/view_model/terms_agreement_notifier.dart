import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_agreement_notifier.g.dart';

@riverpod
class TermsAgreementNotifier extends _$TermsAgreementNotifier {
  @override
  Map<int, bool> build() {
    return {};
  }

  /// Toggle agreement state for a specific term
  void toggleAgreement(int termDefinitionId) {
    state = {
      ...state,
      termDefinitionId: !(state[termDefinitionId] ?? false),
    };
  }

  /// Check if a specific term is agreed
  bool isTermAgreed(int termDefinitionId) {
    return state[termDefinitionId] ?? false;
  }

  /// Reset all agreements
  void reset() {
    state = {};
  }

  /// Set agreements from a list of term IDs (for batch operations)
  void setAgreedTerms(List<int> termIds) {
    state = {
      for (int id in termIds) id: true,
    };
  }

  /// Get all agreed term IDs
  List<int> getAgreedTermIds() {
    return state.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Provider to check if all required terms are agreed
@riverpod
bool allRequiredTermsAgreed(
  Ref ref,
  List<int> requiredTermIds,
) {
  final agreements = ref.watch(termsAgreementProvider);
  return requiredTermIds.every((id) => agreements[id] ?? false);
}
