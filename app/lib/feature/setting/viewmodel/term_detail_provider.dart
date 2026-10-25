import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'term_detail_provider.g.dart';

@riverpod
Future<Term?> termDetail(Ref ref, TermsService termsService, int termId) {
  return termsService.findTerm(termId);
}
