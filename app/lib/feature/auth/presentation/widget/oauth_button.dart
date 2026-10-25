import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/auth/model/oauth_provider.dart';

class OauthButton extends StatelessWidget {
  final OauthProvider provider;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  const OauthButton({
    super.key,
    required this.provider,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isKakao = provider == OauthProvider.kakao;
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final label = isKakao ? '카카오로 계속하기' : 'Google로 계속하기';
    final foreground = const Color(0xFF191919);
    final background = isKakao ? const Color(0xFFFEE500) : Colors.white;

    return ImHerePressable(
      enabled: enabled,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.resolve(ImHereRadius.md)),
          side: isKakao ? BorderSide.none : BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: metrics.resolve(52),
            child: Row(
              children: [
                SizedBox(width: metrics.resolve(ImHereSpace.md)),
                AnimatedSwitcher(
                  duration: ImHereMotion.colorOf(context),
                  child: loading
                      ? SizedBox.square(
                          key: const ValueKey('loader'),
                          dimension: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        )
                      : Image.asset(
                          isKakao ? 'assets/kakao.png' : 'assets/google.png',
                          key: ValueKey(provider),
                          width: 24,
                          height: 24,
                        ),
                ),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: foreground),
                  ),
                ),
                SizedBox(width: metrics.resolve(40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
