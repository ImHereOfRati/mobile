import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/auth/model/service/terms/terms_service.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'terms_acceptance_controller.g.dart';

@Riverpod(keepAlive: true)
AnalyticsReporter authAnalyticsReporter(Ref ref) => FirebaseAnalyticsReporter();

enum TermsAcceptanceStatus { idle, loading, completed, failure }

class TermsAcceptanceState {
  final TermsAcceptanceStatus status;
  final String? errorMessage;

  const TermsAcceptanceState(this.status, {this.errorMessage});

  const TermsAcceptanceState.idle() : this(TermsAcceptanceStatus.idle);
}

@riverpod
class TermsAcceptanceController extends _$TermsAcceptanceController {
  late AuthService _authService;
  late AnalyticsReporter _analytics;

  @override
  TermsAcceptanceState build(AuthService authService) {
    _authService = authService;
    _analytics = ref.watch(authAnalyticsReporterProvider);
    return const TermsAcceptanceState.idle();
  }

  Future<bool> accept(Iterable<Term> terms, Set<int> agreedIds) async {
    state = const TermsAcceptanceState(TermsAcceptanceStatus.loading);
    try {
      await _authService.activateWithTerms(
        terms
            .map(
              (term) => <String, Object?>{
                'id': term.id,
                'agreed': agreedIds.contains(term.id),
              },
            )
            .toList(growable: false),
      );
      final requiredCount = terms.where((term) => term.isRequired).length;
      final optionalCount = terms.length - requiredCount;
      try {
        await _analytics.logEvent(
          'terms_accepted',
          parameters: {
            'required_count': requiredCount,
            'optional_count': optionalCount,
          },
        );
      } catch (error, stack) {
        AppLogger.error('Terms analytics failed', error, stack);
      }
      if (!ref.mounted) return false;
      state = const TermsAcceptanceState(TermsAcceptanceStatus.completed);
      return true;
    } catch (error, stack) {
      AppLogger.error('Terms activation failed', error, stack);
      if (ref.mounted) {
        state = const TermsAcceptanceState(
          TermsAcceptanceStatus.failure,
          errorMessage: '약관 동의를 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
        );
      }
      return false;
    }
  }
}
