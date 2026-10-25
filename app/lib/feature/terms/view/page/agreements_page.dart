import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/terms/view/page/term_detail_page.dart';
import 'package:iamhere/feature/terms/viewmodel/agreements_view_model.dart';

class AgreementsPage extends ConsumerWidget {
  final TermsService termsService;

  const AgreementsPage({super.key, required this.termsService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreements = ref.watch(agreementsViewModelProvider(termsService));
    final colors = ImHereColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ImHereTopBar(
            title: '약관 동의 관리',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: agreements.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.action),
              ),
              error: (_, __) => ImHereStatePanel(
                glyph: ImHereGlyph.close,
                title: '동의 내역을 불러오지 못했어요',
                description: '연결을 확인하고 다시 시도해 주세요.',
                actionLabel: '다시 시도',
                onAction: () =>
                    ref.invalidate(agreementsViewModelProvider(termsService)),
                size: ImHereStateSize.large,
              ),
              data: (items) => items.isEmpty
                  ? const ImHereStatePanel(
                      glyph: ImHereGlyph.close,
                      title: '표시할 약관이 없어요',
                      size: ImHereStateSize.large,
                    )
                  : _AgreementList(items: items, termsService: termsService),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementList extends ConsumerWidget {
  final List<TermAgreement> items;
  final TermsService termsService;

  const _AgreementList({required this.items, required this.termsService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = ImHereColors.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.md),
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.xl),
      ),
      children: [
        Text(
          '동의한 약관을 확인하고 선택 약관의 동의를 변경할 수 있어요.',
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        SizedBox(height: metrics.resolve(ImHereSpace.md)),
        for (final item in items) ...[
          _AgreementCard(
            item: item,
            termsService: termsService,
            onChange: (action) => _change(context, ref, item.term, action),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
        ],
      ],
    );
  }

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    Term term,
    _AgreementAction action,
  ) async {
    final viewModel = ref.read(
      agreementsViewModelProvider(termsService).notifier,
    );
    if (action == _AgreementAction.withdraw) {
      final confirmed = await showImHereDialog(
        context,
        title: '${term.title} 동의를 철회할까요?',
        confirmLabel: '동의 철회',
        destructive: true,
      );
      if (confirmed != true) return;
    }
    final message = switch (action) {
      _AgreementAction.agree => await viewModel.agree(term),
      _AgreementAction.renew => await viewModel.renew(term),
      _AgreementAction.withdraw => await viewModel.withdraw(term),
    };
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _AgreementAction { agree, renew, withdraw }

class _AgreementCard extends StatelessWidget {
  final TermAgreement item;
  final TermsService termsService;
  final ValueChanged<_AgreementAction> onChange;

  const _AgreementCard({
    required this.item,
    required this.termsService,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final term = item.term;
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = ImHereColors.of(context);
    final agreedDate = item.latest?.occurredAt;
    final status = item.isAgreed
        ? '${agreedDate != null && agreedDate.length >= 10 ? agreedDate.substring(0, 10) : ''} 동의'
        : '동의하지 않음';

    return ImHereSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(term.title, style: textTheme.titleSmall)),
              ImHereBadge(
                label: term.isRequired ? '필수' : '선택',
                tone: term.isRequired
                    ? ImHereBadgeTone.action
                    : ImHereBadgeTone.neutral,
              ),
            ],
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
          Text(
            '$status · v${term.version}',
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          Wrap(
            spacing: metrics.resolve(ImHereSpace.xs),
            runSpacing: metrics.resolve(ImHereSpace.xs),
            children: [
              ImHereButton(
                label: '약관 보기',
                tone: ImHereButtonTone.weak,
                size: ImHereButtonSize.sm,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TermDetailPage(
                      termsService: termsService,
                      termId: term.id,
                    ),
                  ),
                ),
              ),
              if (item.needsRenewal)
                ImHereButton(
                  label: '개정 약관 재동의',
                  size: ImHereButtonSize.sm,
                  onPressed: () => onChange(_AgreementAction.renew),
                ),
              if (!item.isAgreed)
                ImHereButton(
                  label: '동의하기',
                  size: ImHereButtonSize.sm,
                  onPressed: () => onChange(_AgreementAction.agree),
                ),
              if (item.isAgreed && !term.isRequired)
                ImHereButton(
                  label: '동의 철회',
                  tone: ImHereButtonTone.danger,
                  size: ImHereButtonSize.sm,
                  onPressed: () => onChange(_AgreementAction.withdraw),
                ),
            ],
          ),
          if (item.isAgreed && term.isRequired) ...[
            SizedBox(height: metrics.resolve(ImHereSpace.sm)),
            Text(
              '필수 약관은 서비스 이용에 필요해 철회할 수 없어요. 회원 탈퇴로만 동의를 거둘 수 있어요.',
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
