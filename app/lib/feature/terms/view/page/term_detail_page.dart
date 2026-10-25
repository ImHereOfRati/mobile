import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/terms/viewmodel/term_detail_provider.dart';

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
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ImHereTopBar(
            title: '약관 상세',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: term.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.action),
              ),
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
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        metrics.resolve(ImHereSpace.gutter),
                        metrics.resolve(ImHereSpace.md),
                        metrics.resolve(ImHereSpace.gutter),
                        metrics.resolve(ImHereSpace.xl),
                      ),
                      children: [
                        ImHereBadge(
                          label: value.isRequired ? '필수 약관' : '선택 약관',
                          tone: value.isRequired
                              ? ImHereBadgeTone.action
                              : ImHereBadgeTone.neutral,
                        ),
                        SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                        Text(value.title, style: textTheme.titleLarge),
                        SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
                        Text(
                          '버전 ${value.version} · 시행일 ${value.effectiveDate}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                        SizedBox(height: metrics.resolve(ImHereSpace.md)),
                        ImHereSurface(
                          child: Text(
                            value.content,
                            style: textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
