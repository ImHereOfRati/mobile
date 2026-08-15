import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/auth/presentation/auth_flow_controller.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        surfaceTintColor: Colors.transparent,
        title: const Text('약관 동의'),
      ),
      body: terms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('약관을 불러오지 못했습니다.\n$error', textAlign: TextAlign.center),
        ),
        data: (items) {
          final requiredOk = items
              .where((term) => term.isRequired)
              .every((term) => _agreed.contains(term.id));
          final allOk = items.isNotEmpty && _agreed.length == items.length;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  children: [
                    Text(
                      '서비스 이용 약관',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('필수 약관에 동의해야 회원가입을 완료할 수 있습니다.'),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('전체 동의'),
                      value: allOk,
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(() {
                              _agreed
                                ..clear()
                                ..addAll(
                                  value == true
                                      ? items.map((term) => term.id)
                                      : const <int>{},
                                );
                            }),
                    ),
                    const Divider(),
                    ...items.expand<Widget>(
                      (term) => [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '[${term.isRequired ? '필수' : '선택'}] ${term.title}',
                          ),
                          value: _agreed.contains(term.id),
                          onChanged: _isSubmitting
                              ? null
                              : (value) => setState(
                                  () => value == true
                                      ? _agreed.add(term.id)
                                      : _agreed.remove(term.id),
                                ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => setState(
                              () => _expandedTerms.contains(term.id)
                                  ? _expandedTerms.remove(term.id)
                                  : _expandedTerms.add(term.id),
                            ),
                            child: Text(
                              _expandedTerms.contains(term.id)
                                  ? '접기'
                                  : '자세히 보기',
                            ),
                          ),
                        ),
                        if (_expandedTerms.contains(term.id))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(term.content),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        requiredOk &&
                            !_isSubmitting &&
                            authState.status != AuthFlowStatus.loading
                        ? () => _submit(items)
                        : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('동의하고 시작하기'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
    ).showSnackBar(SnackBar(content: Text(message ?? '약관 동의 처리에 실패했습니다.')));
  }
}
