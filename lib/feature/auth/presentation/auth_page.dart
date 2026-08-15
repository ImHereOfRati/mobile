import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/auth/presentation/auth_flow_controller.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  final AuthFlowDependencies dependencies;
  final VoidCallback onAuthenticated;

  const AuthPage({
    super.key,
    required this.dependencies,
    required this.onAuthenticated,
  });

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  OauthProvider? _pendingProvider;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider(widget.dependencies));
    final busy = state.status == AuthFlowStatus.loading;
    final error = state.status == AuthFlowStatus.failure
        ? state.errorMessage
        : null;

    Future<void> login(OauthProvider provider) async {
      if (busy) return;
      setState(() => _pendingProvider = provider);
      try {
        final next = await ref
            .read(authFlowControllerProvider(widget.dependencies).notifier)
            .signIn(provider);
        if (!context.mounted) return;
        if (next == AuthFlowStatus.pending) context.go('/terms');
        if (next == AuthFlowStatus.authenticated) {
          widget.onAuthenticated();
        }
      } finally {
        if (mounted) setState(() => _pendingProvider = null);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 56,
              ),
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: constraints.maxWidth > 360
                      ? 360
                      : constraints.maxWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ImHere',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            error,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _OauthButton(
                            provider: OauthProvider.kakao,
                            loading: _pendingProvider == OauthProvider.kakao,
                            onPressed: () => login(OauthProvider.kakao),
                          ),
                          const SizedBox(width: 24),
                          _OauthButton(
                            provider: OauthProvider.google,
                            loading: _pendingProvider == OauthProvider.google,
                            onPressed: () => login(OauthProvider.google),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OauthButton extends StatelessWidget {
  final OauthProvider provider;
  final bool loading;
  final VoidCallback onPressed;

  const _OauthButton({
    required this.provider,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isKakao = provider == OauthProvider.kakao;
    final label = isKakao ? '카카오 로그인' : 'Google로 계속하기';

    return SizedBox(
      width: 72,
      height: 72,
      child: Semantics(
        button: true,
        enabled: !loading,
        label: label,
        child: GestureDetector(
          onTap: loading ? null : onPressed,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isKakao ? const Color(0xFFFEE500) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE9E9E7)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isKakao)
                  Image.asset(
                    'assets/kakao.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  )
                else
                  Image.asset('assets/google.png', width: 36, height: 36),
                if (loading)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
