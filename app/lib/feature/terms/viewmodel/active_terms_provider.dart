import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_terms_provider.g.dart';

@riverpod
Future<List<Term>> activeTerms(Ref ref, TermsService termsService) {
  return termsService.loadActiveTerms();
}
