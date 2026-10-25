import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/setting/view/widget/term_requirement_badge.dart';
import 'package:iamhere/feature/terms/view/widget/term_content_sheet.dart';
import 'package:iamhere/feature/setting/viewmodel/agreements_view_model.dart';

class AgreementsPage extends ConsumerWidget {
  final TermsService termsService;

  const AgreementsPage({super.key, required this.termsService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreements = ref.watch(agreementsViewModelProvider(termsService));
    final colors = ImHereColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      // 상단은 앱 셸의 ImHere 로고 헤더만 쓴다.
      body: agreements.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.action)),
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
        metrics.resolve(ImHereSpace.lg),
        metrics.resolve(ImHereSpace.gutter),
        metrics.resolve(ImHereSpace.xl),
      ),
      children: [
        Text('동의 내역', style: textTheme.titleLarge),
        SizedBox(height: metrics.resolve(ImHereSpace.xs)),
        Text(
          '동의한 약관을 확인하고 선택 약관의 동의를 바꿀 수 있어요.',
          style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        SizedBox(height: metrics.resolve(ImHereSpace.lg)),
        for (final item in items) ...[
          _AgreementCard(
            item: item,
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
  final ValueChanged<_AgreementAction> onChange;

  const _AgreementCard({required this.item, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final term = item.term;
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = ImHereColors.of(context);

    return ImHereSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(term.title, style: textTheme.titleSmall)),
              SizedBox(width: metrics.resolve(ImHereSpace.xs)),
              TermRequirementBadge(isRequired: term.isRequired),
              SizedBox(width: metrics.resolve(ImHereSpace.xxs)),
              _statusBadge(),
            ],
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
          Text(
            _description(),
            style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.sm)),
          Row(
            children: [
              ImHereButton(
                label: '약관 보기',
                tone: ImHereButtonTone.ghost,
                size: ImHereButtonSize.xs,
                onPressed: () => _viewTerm(context),
              ),
              const Spacer(),
              ?_action(),
            ],
          ),
          if (item.isAgreed && term.isRequired) ...[
            SizedBox(height: metrics.resolve(ImHereSpace.xs)),
            Text(
              '필수 약관은 서비스 이용에 필요해 철회할 수 없어요.\n회원 탈퇴로만 동의를 거둘 수 있어요.',
              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  /// 약관 전문은 화면을 옮기지 않고 팝업으로 보여 준다.
  /// 아직 동의하지 않은 약관은 팝업에서 바로 동의할 수 있다.
  Future<void> _viewTerm(BuildContext context) async {
    final agreed = await showTermContentSheet(
      context,
      item.term,
      agreed: item.isAgreed,
    );
    if (agreed == true) onChange(_AgreementAction.agree);
  }

  Widget _statusBadge() {
    if (item.needsRenewal) {
      return const ImHereBadge(
        label: '재동의 필요',
        tone: ImHereBadgeTone.warning,
        size: ImHereBadgeSize.medium,
      );
    }
    return ImHereBadge(
      label: item.isAgreed ? '동의함' : '동의 안 함',
      tone: item.isAgreed ? ImHereBadgeTone.success : ImHereBadgeTone.neutral,
      size: ImHereBadgeSize.medium,
    );
  }

  String _description() {
    final at = item.latest?.occurredAt;
    final date = at != null && at.length >= 10 ? at.substring(0, 10) : null;
    final version = 'v${item.term.version}';
    return item.isAgreed && date != null ? '$date 동의 · $version' : version;
  }

  /// 카드마다 강조 버튼은 하나만 둔다.
  Widget? _action() {
    if (item.needsRenewal) {
      return ImHereButton(
        label: '개정 약관 재동의',
        size: ImHereButtonSize.xs,
        onPressed: () => onChange(_AgreementAction.renew),
      );
    }
    if (!item.isAgreed) {
      return ImHereButton(
        label: '동의하기',
        size: ImHereButtonSize.xs,
        onPressed: () => onChange(_AgreementAction.agree),
      );
    }
    if (!item.term.isRequired) {
      return ImHereButton(
        label: '동의 철회',
        tone: ImHereButtonTone.quiet,
        size: ImHereButtonSize.xs,
        onPressed: () => onChange(_AgreementAction.withdraw),
      );
    }
    return null;
  }
}
