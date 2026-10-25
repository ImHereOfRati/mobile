import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/auth/presentation/flow/auth_flow_controller.dart';
import 'package:iamhere/feature/terms/service/terms_service.dart';

class TermsPage extends ConsumerStatefulWidget {
  final AuthFlowDependencies dependencies;
  final TermsService termsService;
  final VoidCallback onDone;

  const TermsPage({
    super.key,
    required this.dependencies,
    required this.termsService,
    required this.onDone,
  });

  @override
  ConsumerState<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<TermsPage> {
  final Set<int> _agreed = <int>{};
  final Set<int> _expandedTerms = <int>{};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final terms = ref.watch(activeTermsProvider(widget.termsService));
    final authState = ref.watch(
      authFlowControllerProvider(widget.dependencies),
    );
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.text,
        surfaceTintColor: Colors.transparent,
        title: const Text('약관 동의'),
      ),
      body: terms.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: colors.action)),
        error: (_, __) => ImHereStatePanel(
          glyph: ImHereGlyph.close,
          title: '약관을 불러오지 못했어요',
          description: '연결을 확인하고 다시 시도해 주세요.',
          actionLabel: '다시 시도',
          onAction: () =>
              ref.invalidate(activeTermsProvider(widget.termsService)),
          secondaryLabel: '로그인으로',
          onSecondary: () => context.go('/auth'),
          size: ImHereStateSize.large,
        ),
        data: (items) {
          if (items.isEmpty) {
            return ImHereStatePanel(
              glyph: ImHereGlyph.close,
              title: '진행할 약관이 없어요',
              description: '잠시 후 다시 시도해 주세요.',
              actionLabel: '다시 시도',
              onAction: () =>
                  ref.invalidate(activeTermsProvider(widget.termsService)),
              secondaryLabel: '로그인으로',
              onSecondary: () => context.go('/auth'),
              size: ImHereStateSize.large,
            );
          }

          final requiredTerms = items.where((term) => term.isRequired).toList();
          final optionalTerms = items
              .where((term) => !term.isRequired)
              .toList();
          final requiredOk = requiredTerms.every(
            (term) => _agreed.contains(term.id),
          );
          final busy =
              _isSubmitting || authState.status == AuthFlowStatus.loading;

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
                    Text('약관을 확인해 주세요', style: textTheme.titleLarge),
                    SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                    Text(
                      '서비스를 계속 이용하려면 필수 약관에 동의해 주세요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                    SizedBox(height: metrics.resolve(ImHereSpace.xl)),
                    if (requiredTerms.isNotEmpty) ...[
                      Text('필수 약관', style: textTheme.titleSmall),
                      SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                      ImHereCheckbox(
                        label: '필수 약관 모두 동의',
                        value: requiredOk,
                        onChanged: busy
                            ? null
                            : (value) => setState(() {
                                final ids = requiredTerms.map(
                                  (term) => term.id,
                                );
                                if (value) {
                                  _agreed.addAll(ids);
                                } else {
                                  _agreed.removeAll(ids);
                                }
                              }),
                      ),
                      SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                      const ImHereBorder(),
                      SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                      for (final term in requiredTerms)
                        ..._termWidgets(term, busy),
                    ],
                    if (optionalTerms.isNotEmpty) ...[
                      SizedBox(height: metrics.resolve(ImHereSpace.md)),
                      Text('선택 약관', style: textTheme.titleSmall),
                      SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                      Text(
                        '동의하지 않아도 서비스를 이용할 수 있어요.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                      for (final term in optionalTerms)
                        ..._termWidgets(term, busy),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: EdgeInsets.fromLTRB(
                  metrics.resolve(ImHereSpace.gutter),
                  metrics.resolve(ImHereSpace.sm),
                  metrics.resolve(ImHereSpace.gutter),
                  metrics.resolve(ImHereSpace.md),
                ),
                child: ImHereButton(
                  label: '동의하고 계속하기',
                  size: ImHereButtonSize.lg,
                  expand: true,
                  loading: _isSubmitting,
                  onPressed: requiredOk && !busy ? () => _submit(items) : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _termWidgets(Term term, bool busy) {
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    return [
      ImHereCheckbox(
        label: '${term.isRequired ? '필수' : '선택'} · ${term.title}',
        value: _agreed.contains(term.id),
        onChanged: busy
            ? null
            : (value) => setState(
                () => value ? _agreed.add(term.id) : _agreed.remove(term.id),
              ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: ImHereButton(
          label: _expandedTerms.contains(term.id)
              ? '${term.title} 내용 접기'
              : '${term.title} 내용 보기',
          tone: ImHereButtonTone.ghost,
          size: ImHereButtonSize.sm,
          onPressed: () => setState(
            () => _expandedTerms.contains(term.id)
                ? _expandedTerms.remove(term.id)
                : _expandedTerms.add(term.id),
          ),
        ),
      ),
      if (_expandedTerms.contains(term.id)) ...[
        SizedBox(height: metrics.resolve(ImHereSpace.xs)),
        ImHereSurface(child: Text(term.content, style: textTheme.bodyMedium)),
      ],
      SizedBox(height: metrics.resolve(ImHereSpace.md)),
    ];
  }

  Future<void> _submit(List<Term> items) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final success = await ref
        .read(authFlowControllerProvider(widget.dependencies).notifier)
        .acceptTerms(items, Set<int>.of(_agreed));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      widget.onDone();
      return;
    }

    final message = ref
        .read(authFlowControllerProvider(widget.dependencies))
        .errorMessage;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message ?? '약관 동의 처리에 실패했어요.')));
  }
}
