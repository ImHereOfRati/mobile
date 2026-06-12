import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:iamhere/feature/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/feature/terms/view_model/terms_agreement_notifier.dart';
import 'package:iamhere/feature/terms/view_model/terms_agreement_provider.dart';
import 'package:iamhere/feature/terms/view_model/terms_consent_view_model.dart';
import 'package:iamhere/feature/terms/view_model/terms_list_view_model.dart';

class TermsListView extends ConsumerStatefulWidget {
  const TermsListView({super.key});

  @override
  ConsumerState<TermsListView> createState() => _TermsListViewState();
}

class _TermsListViewState extends ConsumerState<TermsListView> {
  bool _hasTriggeredAutoActivation = false;

  @override
  Widget build(BuildContext context) {
    final termsAsync = ref.watch(termsListViewModelProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: termsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          error: (_, __) => _buildErrorState(context, ref),
          data: (terms) => _buildBody(context, ref, terms),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<TermsListRequestDto> terms,
  ) {
    final consentState = ref.watch(termsConsentViewModelProvider);

    if (terms.isEmpty) {
      _scheduleAutoActivationIfNeeded();
      return _buildAutoActivationBody(context, ref, consentState);
    }

    final termIds = terms.map((t) => t.id).toList();
    final requiredIds = terms
        .where((t) => t.isRequired)
        .map((t) => t.id)
        .toList();

    final agreedMap = ref.watch(termsAgreementProvider);
    final isAllAgreed = agreedMap.length == terms.length && terms.isNotEmpty;
    final allRequiredAgreed = ref.watch(
      allRequiredTermsAgreedProvider(requiredIds),
    );

    ref.listen(termsConsentViewModelProvider, (_, next) {
      if (next is AsyncData && next.value != null) {
        AppRoutes.goToGeofence(context);
      }
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('약관 동의에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    });

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: [
              SizedBox(height: 52.h),
              _buildHeader(context),
              SizedBox(height: 40.h),
              _buildAllAgreeBox(context, ref, termIds, isAllAgreed),
              SizedBox(height: 24.h),
              ...terms.map((term) => _buildTermItem(context, ref, term)),
            ],
          ),
        ),
        _buildBottomAction(context, ref, allRequiredAgreed, terms),
      ],
    );
  }

  void _scheduleAutoActivationIfNeeded() {
    if (_hasTriggeredAutoActivation) return;
    _hasTriggeredAutoActivation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(termsConsentViewModelProvider.notifier)
          .submitConsents(const [], const {});
    });
  }

  Widget _buildAutoActivationBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> consentState,
  ) {
    final cs = Theme.of(context).colorScheme;

    if (consentState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).dividerColor,
            ),
            SizedBox(height: 16.h),
            Text(
              '시작 준비를 마치지 못했습니다.',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 15.sp,
                color: cs.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(termsConsentViewModelProvider.notifier)
                    .submitConsents(const [], const {});
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary),
          SizedBox(height: 20.h),
          Text(
            '시작 준비 중입니다...',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 16.sp,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          'Imhere',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 42.sp,
            fontWeight: FontWeight.w900,
            color: cs.primary,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          '환영합니다!',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          '필수 약관에만 동의하면\n바로 시작할 수 있어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 15.sp,
            color: cs.onSurface.withValues(alpha: 0.55),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildAllAgreeBox(
    BuildContext context,
    WidgetRef ref,
    List<int> allIds,
    bool isAllAgreed,
  ) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => ref.read(termsAgreementProvider.notifier).toggleAll(allIds),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor, width: 1.2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            _buildCircleCheckbox(context, isAllAgreed, isMain: true),
            SizedBox(width: 14.w),
            Text(
              '전체 동의',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(
    BuildContext context,
    WidgetRef ref,
    TermsListRequestDto term,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isAgreed = ref.watch(
      termsAgreementProvider.select((m) => m[term.id] ?? false),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref
                .read(termsAgreementProvider.notifier)
                .toggleAgreement(term.id),
            child: _buildCircleCheckbox(context, isAgreed),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Row(
              children: [
                Text(
                  term.isRequired ? '[필수] ' : '[선택] ',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: term.isRequired
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                Text(
                  term.title,
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showTermsDetailDialog(context, term),
            child: Text(
              '상세보기',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: cs.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDetailDialog(BuildContext context, TermsListRequestDto term) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            term.title,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              term.content,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: cs.onSurface,
                height: 1.6,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                '닫기',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  color: cs.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCircleCheckbox(
    BuildContext context,
    bool isChecked, {
    bool isMain = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: isMain ? 24.r : 22.r,
      height: isMain ? 24.r : 22.r,
      decoration: BoxDecoration(
        color: isChecked ? cs.primary : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isChecked ? cs.primary : Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
      child: isChecked
          ? Icon(Icons.check, size: 14.r, color: cs.onPrimary)
          : null,
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    WidgetRef ref,
    bool allRequiredAgreed,
    List<TermsListRequestDto> terms,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isLoading = ref.watch(
      termsConsentViewModelProvider.select((s) => s.isLoading),
    );
    final canSubmit = allRequiredAgreed && !isLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: canSubmit
                  ? () {
                      final agreementsMap = ref.read(termsAgreementProvider);
                      ref
                          .read(termsConsentViewModelProvider.notifier)
                          .submitConsents(terms, agreementsMap);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.08),
                foregroundColor: cs.onPrimary,
                disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24.r,
                      height: 24.r,
                      child: CircularProgressIndicator(
                        color: cs.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      '동의하고 시작하기',
                      style: TextStyle(
                        fontFamily: 'BMHANNAAir',
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: allRequiredAgreed
                            ? cs.onPrimary
                            : cs.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '선택 항목은 동의하지 않아도 이용 가능해요',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).dividerColor,
          ),
          SizedBox(height: 16.h),
          Text(
            '약관 정보를 불러오지 못했습니다.',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 15.sp,
              color: cs.onSurface,
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(termsListViewModelProvider),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
