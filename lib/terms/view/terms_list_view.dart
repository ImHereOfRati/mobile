import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/terms/view_model/terms_agreement_notifier.dart';
import 'package:iamhere/terms/view_model/terms_agreement_provider.dart';
import 'package:iamhere/terms/view_model/terms_list_view_model.dart';

class TermsListView extends ConsumerWidget {
  const TermsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(termsListViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        centerTitle: true,
        title: Text(
          '약관 동의',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -0.374,
          ),
        ),
      ),
      body: termsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0071E3)),
        ),
        error: (_, __) => _buildErrorState(ref),
        data: (terms) => _buildContent(context, ref, terms),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Color(0xFF6E6E73),
            ),
            SizedBox(height: 20.h),
            Text(
              '약관을 불러올 수 없습니다',
              style: TextStyle(
                fontFamily: 'GmarketSans',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '네트워크 연결을 확인하고 다시 시도해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 14.sp,
                color: const Color(0xFF6E6E73),
                letterSpacing: -0.224,
              ),
            ),
            SizedBox(height: 28.h),
            TextButton(
              onPressed: () => ref.invalidate(termsListViewModelProvider),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0071E3),
              ),
              child: Text(
                '다시 시도 →',
                style: TextStyle(fontSize: 14.sp, letterSpacing: -0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<TermsListRequestDto> terms,
  ) {
    final requiredIds = terms
        .where((t) => t.isRequired)
        .map((t) => t.termDefinitionId)
        .toList();
    final allAgreed = ref.watch(allRequiredTermsAgreedProvider(requiredIds));

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            itemCount: terms.length,
            itemBuilder: (_, i) => _buildTermCard(context, ref, terms[i]),
          ),
        ),
        _buildActionArea(context, ref, allAgreed),
      ],
    );
  }

  Widget _buildTermCard(
    BuildContext context,
    WidgetRef ref,
    TermsListRequestDto term,
  ) {
    final isAgreed = ref.watch(
      termsAgreementProvider.select(
        (m) => m[term.termDefinitionId] ?? false,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: GestureDetector(
        onTap: () => ref
            .read(termsAgreementProvider.notifier)
            .toggleAgreement(term.termDefinitionId),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22.r,
                  height: 22.r,
                  decoration: BoxDecoration(
                    color: isAgreed
                        ? const Color(0xFF0071E3)
                        : Colors.transparent,
                    border: Border.all(
                      color: isAgreed
                          ? const Color(0xFF0071E3)
                          : const Color(0xFFD2D2D7),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: isAgreed
                      ? Icon(Icons.check, size: 14.r, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    term.title,
                    style: TextStyle(
                      fontFamily: 'BMHANNAAir',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D1D1F),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (term.isRequired)
                  Container(
                    margin: EdgeInsets.only(right: 8.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071E3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(980.r),
                    ),
                    child: Text(
                      '필수',
                      style: TextStyle(
                        fontFamily: 'BMHANNAAir',
                        fontSize: 11.sp,
                        color: const Color(0xFF0071E3),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () =>
                      context.push('/terms-detail/${term.termDefinitionId}'),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFD2D2D7),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    WidgetRef ref,
    bool allAgreed,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFD2D2D7), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!allAgreed)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Text(
                '모든 필수 약관에 동의해주세요',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 12.sp,
                  color: const Color(0xFFFF3B30),
                  letterSpacing: -0.12,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: allAgreed ? () => context.go('/geofence') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: allAgreed
                    ? const Color(0xFF1D1D1F)
                    : const Color(0xFFD2D2D7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                '동의하고 시작하기',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.374,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
