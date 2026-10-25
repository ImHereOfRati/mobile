import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/setting/view/widget/term_requirement_badge.dart';
import 'package:iamhere/feature/setting/viewmodel/term_detail_provider.dart';

class TermDetailPage extends ConsumerWidget {
  final TermsService termsService;
  final int termId;

  const TermDetailPage({
    super.key,
    required this.termsService,
    required this.termId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final term = ref.watch(termDetailProvider(termsService, termId));
    final colors = ImHereColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      // 상단은 앱 셸의 ImHere 로고 헤더만 쓴다.
      body: term.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.action)),
        error: (_, __) => ImHereStatePanel(
          glyph: ImHereGlyph.close,
          title: '약관을 불러오지 못했어요',
          description: '연결을 확인하고 다시 시도해 주세요.',
          actionLabel: '다시 시도',
          onAction: () =>
              ref.invalidate(termDetailProvider(termsService, termId)),
          size: ImHereStateSize.large,
        ),
        data: (value) => value == null
            ? const ImHereStatePanel(
                glyph: ImHereGlyph.close,
                title: '약관을 찾을 수 없어요',
                size: ImHereStateSize.large,
              )
            : _TermDetail(term: value),
      ),
    );
  }
}

class _TermDetail extends StatelessWidget {
  final Term term;

  const _TermDetail({required this.term});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.lg),
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.xl),
        ),
        children: [
          TermRequirementBadge(isRequired: term.isRequired),
          SizedBox(height: metrics.resolve(ImHereSpace.xs)),
          Text(term.title, style: textTheme.titleLarge),
          SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
          Text(
            '버전 ${term.version} · 시행일 ${term.effectiveDay}',
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.md)),
          const ImHereBorder(),
          SizedBox(height: metrics.resolve(ImHereSpace.md)),
          Text(
            term.content,
            style: textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
