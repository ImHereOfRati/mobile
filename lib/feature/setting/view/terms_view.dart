import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';
import 'package:iamhere/feature/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/feature/terms/view_model/terms_list_view_model.dart';

class TermsView extends ConsumerWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(termsListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '약관 보기',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 18.sp,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: termsAsync.when(
          loading: () => const Center(child: ImHereLoadingIndicator(height: 32)),
          error: (_, __) => _TermsErrorState(
            onRetry: () => ref.invalidate(termsListViewModelProvider),
          ),
          data: (terms) => _TermsBody(terms: terms),
        ),
      ),
    );
  }
}

class _TermsBody extends StatelessWidget {
  final List<TermsListRequestDto> terms;

  const _TermsBody({required this.terms});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
      children: [
        Text(
          'ImHere 약관',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 26.sp,
            fontWeight: FontWeight.w900,
            color: cs.primary,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '서버에서 제공하는 최신 약관입니다.',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 14.sp,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
        SizedBox(height: 20.h),
        if (terms.isEmpty)
          _EmptyTermsCard(colorScheme: cs)
        else
          ...terms.map((term) => _TermCard(term: term)),
        SizedBox(height: 28.h),
        const _DeveloperInfoFooter(),
      ],
    );
  }
}

class _TermCard extends StatelessWidget {
  final TermsListRequestDto term;

  const _TermCard({required this.term});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Card(
        elevation: 0,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          title: Text(
            term.title,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          subtitle: Text(
            term.isRequired ? '필수 약관' : '선택 약관',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: term.isRequired ? cs.primary : cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                term.content,
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 14.sp,
                  height: 1.6,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTermsCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyTermsCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Text(
        '표시할 약관이 없습니다.',
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 14.sp,
          color: colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

class _DeveloperInfoFooter extends StatelessWidget {
  const _DeveloperInfoFooter();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Text(
            '개발자 정보',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '고동수',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'kod66170@gmail.com',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _TermsErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).dividerColor),
          SizedBox(height: 16.h),
          Text(
            '약관 정보를 불러오지 못했습니다.',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 15.sp,
              color: cs.onSurface,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
