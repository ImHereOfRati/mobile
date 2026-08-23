import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/auth/presentation/auth_flow_controller.dart';
import 'package:iamhere/feature/auth/service/oauth_provider.dart';
import 'package:iamhere/shell/view/background_location_disclosure_details.dart';

class AuthPage extends ConsumerStatefulWidget {
  final AuthFlowDependencies dependencies;
  final VoidCallback onAuthenticated;
  final Future<void> Function() requestLocationPermission;

  const AuthPage({
    super.key,
    required this.dependencies,
    required this.onAuthenticated,
    required this.requestLocationPermission,
  });

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  OauthProvider? _pendingProvider;

  static const _backgroundDisclosureKey =
      'background_location_disclosure_accepted_v1';
  static const _secureStorage = FlutterSecureStorage();

  Future<bool> _hasBackgroundLocationConsent() async =>
      await _secureStorage.read(key: _backgroundDisclosureKey) == 'accepted';

  Future<bool?> _showBackgroundLocationDisclosure() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('시작 전 안내'),
        content: const SingleChildScrollView(
          child: BackgroundLocationDisclosureDetails(),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('동의하고 계속'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authFlowControllerProvider(widget.dependencies));
    final busy = state.status == AuthFlowStatus.loading;
    final error = state.status == AuthFlowStatus.failure
        ? state.errorMessage
        : null;

    Future<void> login(OauthProvider provider) async {
      if (busy || _pendingProvider != null) return;
      var shouldRequestLocationPermission = false;
      if (Platform.isAndroid && !await _hasBackgroundLocationConsent()) {
        final agreed = await _showBackgroundLocationDisclosure();
        if (!mounted || agreed != true) return;
        await _secureStorage.write(
          key: _backgroundDisclosureKey,
          value: 'accepted',
        );
        shouldRequestLocationPermission = true;
      }
      setState(() => _pendingProvider = provider);
      try {
        if (shouldRequestLocationPermission) {
          try {
            await widget.requestLocationPermission();
          } catch (error) {
            AppLogger.warning(
              'Location permission request failed before sign-in: $error',
            );
          }
        }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Copy Section (Texture style left aligned)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 36),
                        // Main Catchphrase
                        const Text(
                          '지금 ImHere와 함께\n자동 알림을 시작하세요',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                            color: Color(0xFF111111),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Brand Logo (lowercase texture style feel)
                        Row(
                          children: [
                            Text(
                              'ImHere',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: -1.0,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 2, top: 18),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom Login & Permissions Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
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

                        // SNS Login Header Label
                        const Text(
                          'SNS 계정으로 간편 로그인하기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // OAuth Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _OauthButton(
                              provider: OauthProvider.kakao,
                              loading: _pendingProvider == OauthProvider.kakao,
                              onPressed: () => login(OauthProvider.kakao),
                            ),
                            const SizedBox(width: 20),
                            _OauthButton(
                              provider: OauthProvider.google,
                              loading: _pendingProvider == OauthProvider.google,
                              onPressed: () => login(OauthProvider.google),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Permissions Brief Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '앱 필수 및 권한 안내',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _PermissionItem(
                                icon: Icons.location_on_outlined,
                                title: '위치 권한',
                                description: '지오펜싱 기반 출발·도착 자동 감지',
                              ),
                              const SizedBox(height: 4),
                              _PermissionItem(
                                icon: Icons.notifications_none_outlined,
                                title: '알림 권한',
                                description: '친구의 출발 및 도착 순간 알림 수신',
                              ),
                              const SizedBox(height: 4),
                              _PermissionItem(
                                icon: Icons.contacts_outlined,
                                title: '연락처 권한',
                                description: '알림을 공유할 친구 및 수신자 등록',
                              ),
                              const SizedBox(height: 4),
                              _PermissionItem(
                                icon: Icons.battery_saver_outlined,
                                title: '배터리 최적화 제외',
                                description: '백그라운드에서 실시간 장소 감지 유지',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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

    // Use AnimatedSwitcher for smooth transition between icon and loader
    final buttonContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: loading
          ? const SizedBox.square(
              key: ValueKey('loader'),
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : isKakao
          ? Image.asset(
              'assets/kakao.png',
              key: const ValueKey('kakao'),
              width: 36,
              height: 36,
            )
          : Image.asset(
              'assets/google.png',
              key: const ValueKey('google'),
              width: 36,
              height: 36,
            ),
    );

    // Vibrant button styling
    final buttonDecoration = BoxDecoration(
      color: isKakao ? const Color(0xFFFEE500) : Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFE9E9E7)),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return SizedBox(
      width: 80,
      height: 80,
      child: Semantics(
        button: true,
        enabled: !loading,
        label: label,
        child: GestureDetector(
          onTap: loading ? null : onPressed,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: buttonDecoration,
            child: Center(child: buttonContent),
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
