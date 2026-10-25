import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:iamhere/feature/auth/viewmodel/sign_in_controller.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/feature/auth/view/widget/auth_story.dart';
import 'package:iamhere/feature/auth/view/widget/oauth_button.dart';
import 'package:iamhere/feature/auth/view/widget/permission_disclosure_dialog.dart';

class AuthPage extends ConsumerStatefulWidget {
  final SocialLoginService authLoginCoordinator;
  final VoidCallback onAuthenticated;
  final Future<void> Function() requestLocationPermission;
  final Future<void> Function()? requestNotificationPermission;

  const AuthPage({
    super.key,
    required this.authLoginCoordinator,
    required this.onAuthenticated,
    required this.requestLocationPermission,
    this.requestNotificationPermission,
  });

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  OauthProvider? _pendingProvider;

  static const _backgroundDisclosureKey =
      'background_location_disclosure_accepted_v1';
  static const _notificationDisclosureKey =
      'notification_disclosure_accepted_v1';
  static const _secureStorage = FlutterSecureStorage();

  Future<bool> _hasBackgroundLocationConsent() async =>
      await _secureStorage.read(key: _backgroundDisclosureKey) == 'accepted';

  Future<bool?> _showBackgroundLocationDisclosure() {
    return showDialog<bool>(
      context: context,
      builder: (_) => const LocationDisclosureDialog(),
    );
  }

  Future<bool?> _showNotificationDisclosure() {
    return showDialog<bool>(
      context: context,
      builder: (_) => const NotificationDisclosureDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      signInControllerProvider(widget.authLoginCoordinator),
    );
    final busy = state.status == SignInStatus.loading;
    final error = state.status == SignInStatus.failure
        ? state.errorMessage
        : null;

    Future<void> login(OauthProvider provider) async {
      if (busy || _pendingProvider != null) return;
      setState(() => _pendingProvider = provider);
      try {
        if (Platform.isAndroid && !await _hasBackgroundLocationConsent()) {
          if (!mounted) return;
          final agreed = await _showBackgroundLocationDisclosure();
          if (!mounted || agreed != true) return;
          await _secureStorage.write(
            key: _backgroundDisclosureKey,
            value: 'accepted',
          );
          try {
            await widget.requestLocationPermission();
          } catch (error) {
            AppLogger.warning(
              'Location permission request failed before sign-in: $error',
            );
          }
        }
        if (widget.requestNotificationPermission != null &&
            await _secureStorage.read(key: _notificationDisclosureKey) !=
                'accepted') {
          if (!mounted) return;
          final agreed = await _showNotificationDisclosure();
          if (!mounted) return;
          if (agreed == true) {
            await _secureStorage.write(
              key: _notificationDisclosureKey,
              value: 'accepted',
            );
            try {
              await widget.requestNotificationPermission!();
            } catch (error) {
              AppLogger.warning(
                'Notification permission request failed before sign-in: $error',
              );
            }
          }
        }
        final next = await ref
            .read(
              signInControllerProvider(widget.authLoginCoordinator).notifier,
            )
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
