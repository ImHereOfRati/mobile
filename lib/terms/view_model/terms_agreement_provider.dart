import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/terms/view_model/terms_agreement_notifier.dart';

/// Provider for terms agreement state
final termsAgreementProvider =
    StateNotifierProvider<TermsAgreementNotifier, Map<int, bool>>((ref) {
  return ref.watch(termsAgreementNotifierProvider.notifier);
});

/// Provider to check if all required terms are agreed
final allRequiredTermsAgreedProvider = Provider.family<bool, List<int>>((ref, requiredTermIds) {
  final notifier = ref.watch(termsAgreementNotifierProvider.notifier);
  return notifier.allRequiredTermsAgreed(requiredTermIds);
});
