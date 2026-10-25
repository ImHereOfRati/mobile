import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:iamhere/feature/auth/viewmodel/sign_in_view_model.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/feature/auth/view/widget/auth_story.dart';
import 'package:iamhere/feature/auth/view/widget/oauth_button.dart';

class AuthPage extends ConsumerStatefulWidget {
  final SocialLoginService authLoginCoordinator;
  final VoidCallback onAuthenticated;

  const AuthPage({
    super.key,
    required this.authLoginCoordinator,
    required this.onAuthenticated,
  });

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  OauthProvider? _pendingProvider;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      signInViewModelProvider(widget.authLoginCoordinator),
    );
    final busy = state.status == SignInStatus.loading;
    final error = state.status == SignInStatus.failure
        ? state.errorMessage
        : null;

    Future<void> login(OauthProvider provider) async {
      if (busy || _pendingProvider != null) return;
      setState(() => _pendingProvider = provider);
      try {
        final next = await ref
            .read(signInViewModelProvider(widget.authLoginCoordinator).notifier)
            .signIn(provider);
        if (!context.mounted) return;
        if (next == SignInStatus.pending) context.go('/terms');
        if (next == SignInStatus.authenticated) {
          widget.onAuthenticated();
        }
      } finally {
        if (mounted) setState(() => _pendingProvider = null);
      }
    }

    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.resolve(ImHereSpace.gutter),
                  vertical: metrics.resolve(ImHereSpace.lg),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ImHereLogo(color: colors.action),
                        SizedBox(height: metrics.resolve(ImHereSpace.xxl)),
                        Text(
                          '출발할 때, 도착할 때\n연락은 ImHere가 대신 보낼게요',
                          style: textTheme.headlineLarge,
                        ),
                        SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                        Text(
                          '알리고 싶은 장소와 반경만 정해두세요.\n앱을 꺼둬도 필요한 순간에 자동으로 보내요.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: metrics.resolve(ImHereSpace.lg),
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              key: const Key('auth-showcase'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: metrics.resolve(ImHereSpace.md),
                                ),
                                const AuthStory(key: Key('auth-story')),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (error != null) ...[
                          ImHereCallout(
                            text: error,
                            title: '로그인하지 못했어요',
                            tone: ImHereCalloutTone.error,
                          ),
                          SizedBox(height: metrics.resolve(ImHereSpace.md)),
                        ],
                        Text('간편하게 시작하기', style: textTheme.titleSmall),
                        SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                        OauthButton(
                          provider: OauthProvider.kakao,
                          loading: _pendingProvider == OauthProvider.kakao,
                          enabled: !busy && _pendingProvider == null,
                          onPressed: () => login(OauthProvider.kakao),
                        ),
                        SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                        OauthButton(
                          provider: OauthProvider.google,
                          loading: _pendingProvider == OauthProvider.google,
                          enabled: !busy && _pendingProvider == null,
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
    );
  }
}
