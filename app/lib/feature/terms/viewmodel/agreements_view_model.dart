import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agreements_view_model.g.dart';

@riverpod
class AgreementsViewModel extends _$AgreementsViewModel {
  late TermsService _termsService;

  @override
  Future<List<TermAgreement>> build(TermsService termsService) {
    _termsService = termsService;
    return termsService.loadAgreements();
  }

  /// 세 동작 모두 성공·실패와 상관없이 사용자에게 보여줄 메시지를 돌려준다.
  Future<String> agree(Term term) => _run(
    () async {
      await _termsService.consent(term);
      if (term.isMarketing) await _setMarketingConsent(true);
    },
    success: '${term.title}에 동의했어요.',
    failure: '동의 상태를 변경하지 못했어요.',
  );

  Future<String> renew(Term term) => _run(
    () => _termsService.consentToRenewal(term),
    success: '개정된 ${term.title}에 다시 동의했어요.',
    failure: '동의 상태를 변경하지 못했어요.',
  );

  Future<String> withdraw(Term term) => _run(
    () async {
      await _termsService.withdraw(term);
      if (term.isMarketing) await _setMarketingConsent(false);
    },
    success: '${term.title} 동의를 철회했어요.',
    failure: '동의 상태를 변경하지 못했어요.',
  );

  // 동의·철회·재동의 모두 서버가 이력을 새로 쌓기 때문에, 성공하면 목록을
  // 다시 읽어 화면 상태를 서버 이력에 맞춘다.
  Future<String> _run(
    Future<void> Function() action, {
    required String success,
    required String failure,
  }) async {
    try {
      await action();
      final refreshed = await _termsService.loadAgreements();
      if (ref.mounted) state = AsyncData(refreshed);
      return success;
    } catch (error, stack) {
      AppLogger.error('Agreement change failed', error, stack);
      return failure;
    }
  }

  Future<void> _setMarketingConsent(bool granted) async {
    try {
      await ref.read(authAnalyticsReporterProvider).setConsent(granted);
    } catch (error, stack) {
      AppLogger.error('Analytics consent update failed', error, stack);
    }
  }
}
