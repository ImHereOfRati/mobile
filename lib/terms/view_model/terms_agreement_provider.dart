import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_agreement_provider.g.dart';

@riverpod
class TermsAgreement extends _$TermsAgreement {
  @override
  Map<int, bool> build() {
    return {};
  }

  void toggleTerm(int id) {
    state = {...state, id: !(state[id] ?? false)};
  }
}

@riverpod
bool allRequiredTermsAgreed(Ref ref, List<int> requiredTermIds) {
  final agreementMap = ref.watch(termsAgreementProvider);

  if (requiredTermIds.isEmpty) return false;
  return requiredTermIds.every((id) => agreementMap[id] ?? false);
}
