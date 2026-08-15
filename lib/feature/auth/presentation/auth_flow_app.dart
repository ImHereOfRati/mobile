import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/auth/presentation/auth_flow_controller.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';

class AuthFlowApp extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final String initialLocation;

  const AuthFlowApp({
    super.key,
    required this.onAuthenticated,
    this.initialLocation = '/auth',
  });

  @override
  State<AuthFlowApp> createState() => _AuthFlowAppState();
}

class _AuthFlowAppState extends State<AuthFlowApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const _AuthPage()),
      GoRoute(
        path: '/terms',
        builder: (_, __) => _TermsPage(onDone: widget.onAuthenticated),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'ImHere',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff425e91)),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}

class _AuthPage extends ConsumerWidget {
  const _AuthPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authFlowControllerProvider);
    final busy = state.status == AuthFlowStatus.loading;
    final error = state.status == AuthFlowStatus.failure
        ? state.errorMessage
        : null;

    Future<void> login(OauthProvider provider) async {
      final next = await ref
          .read(authFlowControllerProvider.notifier)
          .signIn(provider);
      if (!context.mounted) return;
      if (next == AuthFlowStatus.pending) context.go('/terms');
      if (next == AuthFlowStatus.authenticated) {
        // The shell changes to the service WebView after the callback.
        final app = context.findAncestorWidgetOfExactType<AuthFlowApp>();
        app?.onAuthenticated();
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.location_on_rounded, size: 72),
              const SizedBox(height: 24),
              Text('ImHere', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                '로그인하고 필요한 서비스만 안전하게 시작해 주세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : () => login(OauthProvider.kakao),
                  icon: const Icon(Icons.chat_bubble),
                  label: const Text('카카오로 로그인'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => login(OauthProvider.google),
                  icon: const Icon(Icons.account_circle),
                  label: const Text('Google로 로그인'),
                ),
              ),
              const SizedBox(height: 16),
              if (busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsPage extends ConsumerStatefulWidget {
  final VoidCallback onDone;

  const _TermsPage({required this.onDone});

  @override
  ConsumerState<_TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<_TermsPage> {
  final Set<int> _agreed = <int>{};

  @override
  Widget build(BuildContext context) {
    final terms = ref.watch(activeTermsProvider);
    final authState = ref.watch(authFlowControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('약관 동의')),
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
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '서비스 이용을 위해 확인해 주세요.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('필수 약관에 동의해야 회원가입을 완료할 수 있습니다.'),
              const SizedBox(height: 24),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('전체 동의'),
                value: allOk,
                onChanged: (value) => setState(() {
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
              ...items.map(
                (term) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '[${term.isRequired ? '필수' : '선택'}] ${term.title}',
                  ),
                  value: _agreed.contains(term.id),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      _agreed.add(term.id);
                    } else {
                      _agreed.remove(term.id);
                    }
                  }),
                  secondary: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(term.title),
                        content: SingleChildScrollView(
                          child: Text(term.content),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('닫기'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    requiredOk && authState.status != AuthFlowStatus.loading
                    ? () async {
                        try {
                          await ref
                              .read(authFlowControllerProvider.notifier)
                              .acceptTerms(items, _agreed);
                          if (mounted) widget.onDone();
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('약관 동의 처리에 실패했습니다: $error')),
                          );
                        }
                      }
                    : null,
                child: const Text('동의하고 시작하기'),
              ),
            ],
          );
        },
      ),
    );
  }
}
