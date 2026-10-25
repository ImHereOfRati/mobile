import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/terms/view/widget/term_content_sheet.dart';
import 'package:iamhere/feature/terms/viewmodel/active_terms_provider.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';

class TermsPage extends ConsumerStatefulWidget {
  final AuthService authService;
  final TermsService termsService;
  final VoidCallback onDone;

  const TermsPage({
    super.key,
    required this.authService,
    required this.termsService,
    required this.onDone,
  });

  @override
  ConsumerState<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<TermsPage> {
  final Set<int> _agreed = <int>{};

  @override
  Widget build(BuildContext context) {
    final terms = ref.watch(activeTermsProvider(widget.termsService));
    final acceptanceState = ref.watch(
      termsAcceptanceViewModelProvider(widget.authService),
    );
    final colors = ImHereColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const ImHereAppHeader(showNotification: false),
          Expanded(
            child: terms.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.action),
              ),
              error: (_, __) => _statePanel(
                title: '약관을 불러오지 못했어요',
                description: '연결을 확인하고 다시 시도해 주세요.',
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _statePanel(
                    title: '진행할 약관이 없어요',
                    description: '잠시 후 다시 시도해 주세요.',
                  );
                }
                return _body(
                  items,
                  busy: acceptanceState.status == TermsAcceptanceStatus.loading,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statePanel({required String title, required String description}) {
    return ImHereStatePanel(
      glyph: ImHereGlyph.close,
      title: title,
      description: description,
      actionLabel: '다시 시도',
      onAction: () => ref.invalidate(activeTermsProvider(widget.termsService)),
      secondaryLabel: '로그인으로',
      onSecondary: () => context.go('/auth'),
      size: ImHereStateSize.large,
    );
  }

  Widget _body(List<Term> items, {required bool busy}) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    final ordered = [
      ...items.where((term) => term.isRequired),
      ...items.where((term) => !term.isRequired),
    ];
    final requiredTerms = ordered.where((term) => term.isRequired).toList();
    final allAgreed = ordered.every((term) => _agreed.contains(term.id));
    final requiredCount = requiredTerms
        .where((term) => _agreed.contains(term.id))
        .length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.lg),
              metrics.resolve(ImHereSpace.gutter),
              metrics.resolve(ImHereSpace.md),
            ),
            children: [
              ImHereLogo(color: colors.action),
              SizedBox(height: metrics.resolve(ImHereSpace.md)),
              Text('서비스 이용을 위해\n약관에 동의해 주세요', style: textTheme.titleLarge),
              SizedBox(height: metrics.resolve(ImHereSpace.xs)),
              Text(
                '필수 약관에 동의하면 바로 시작할 수 있어요.',
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.xl)),
              _termGroup(ordered, busy: busy),
            ],
          ),
        ),
        _footer(
          ordered,
          allAgreed: allAgreed,
          requiredCount: requiredCount,
          requiredTotal: requiredTerms.length,
          busy: busy,
          onSubmit: () => _submit(items),
        ),
      ],
    );
  }

  /// 한 손으로 닿는 화면 아래쪽에 전체 동의와 계속하기 버튼을 함께 고정한다.
  Widget _footer(
    List<Term> ordered, {
    required bool allAgreed,
    required int requiredCount,
    required int requiredTotal,
    required bool busy,
    required VoidCallback onSubmit,
  }) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final requiredDone = requiredCount == requiredTotal;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: metrics.resolve(ImHereSpace.md)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            metrics.resolve(ImHereSpace.gutter),
            metrics.resolve(ImHereSpace.sm),
            metrics.resolve(ImHereSpace.gutter),
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _agreeAllCard(
                ordered,
                allAgreed: allAgreed,
                requiredCount: requiredCount,
                requiredTotal: requiredTotal,
                busy: busy,
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.sm)),
              ImHereButton(
                label: '동의하고 계속하기',
                size: ImHereButtonSize.lg,
                expand: true,
                loading: busy,
                onPressed: requiredDone && !busy ? onSubmit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 전체 동의. 모두 동의하면 카드가 브랜드 색으로 바뀌어 상태가 한눈에 보인다.
  Widget _agreeAllCard(
    List<Term> ordered, {
    required bool allAgreed,
    required int requiredCount,
    required int requiredTotal,
    required bool busy,
  }) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final requiredDone = requiredCount == requiredTotal;

    return AnimatedContainer(
      duration: ImHereMotion.colorOf(context),
      curve: ImHereMotion.easing,
      padding: EdgeInsets.symmetric(
        horizontal: metrics.resolve(ImHereSpace.md),
        vertical: metrics.resolve(ImHereSpace.xs),
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: allAgreed ? colors.action : colors.border,
          width: metrics.resolve(1.5),
        ),
        borderRadius: BorderRadius.circular(metrics.resolve(ImHereRadius.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImHereCheckbox(
            label: '전체 동의 (선택 포함)',
            value: allAgreed,
            onChanged: busy
                ? null
                : (value) => setState(() {
                    final ids = ordered.map((term) => term.id);
                    value ? _agreed.addAll(ids) : _agreed.removeAll(ids);
                  }),
            action: requiredTotal == 0
                ? null
                : ImHereBadge(
                    label: '필수 $requiredCount/$requiredTotal',
                    tone: requiredDone
                        ? ImHereBadgeTone.success
                        : ImHereBadgeTone.action,
                    size: ImHereBadgeSize.medium,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _termGroup(List<Term> ordered, {required bool busy}) {
    return Column(
      children: [for (final term in ordered) _termRow(term, busy: busy)],
    );
  }

  Widget _termRow(Term term, {required bool busy}) {
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final agreed = _agreed.contains(term.id);

    return ImHereCheckbox(
      label: term.title,
      value: agreed,
      onChanged: busy ? null : (value) => _setAgreed(term, value),
      prefix: Text(
        term.isRequired ? '필수' : '선택',
        style: textTheme.labelLarge?.copyWith(
          color: term.isRequired ? colors.action : colors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
      action: IconButton(
        tooltip: '${term.title} 보기',
        onPressed: () => _viewTerm(term, agreed: agreed),
        icon: ImHereIcon(
          glyph: ImHereGlyph.chevron,
          size: 20,
          color: colors.textMuted,
        ),
      ),
    );
  }

  void _setAgreed(Term term, bool value) =>
      setState(() => value ? _agreed.add(term.id) : _agreed.remove(term.id));

  Future<void> _viewTerm(Term term, {required bool agreed}) async {
    final agreedInSheet = await showTermContentSheet(
      context,
      term,
      agreed: agreed,
    );
    if (agreedInSheet == true && mounted) _setAgreed(term, true);
  }

  Future<void> _submit(List<Term> items) async {
    final provider = termsAcceptanceViewModelProvider(widget.authService);
    if (ref.read(provider).status == TermsAcceptanceStatus.loading) return;

    final success = await ref
        .read(provider.notifier)
        .accept(items, Set<int>.of(_agreed));

    if (!mounted) return;

    if (success) {
      widget.onDone();
      return;
    }

    final message = ref.read(provider).errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? '약관 동의 처리에 실패했어요.')));
  }
}
