import 'package:iamhere/terms/view_model/terms_agreement_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_agreement_provider.g.dart';

@riverpod
bool allRequiredTermsAgreed(Ref ref, List<int> requiredTermIds) {
  final agreementMap = ref.watch(termsAgreementProvider);

  if (requiredTermIds.isEmpty) return true;
  return requiredTermIds.every((id) => agreementMap[id] ?? false);
}
