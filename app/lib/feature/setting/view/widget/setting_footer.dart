import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

class SettingFooter extends StatelessWidget {
  final VoidCallback onSignOut;
  final VoidCallback onWithdraw;
  final bool withdrawing;

  const SettingFooter({
    super.key,
    required this.onSignOut,
    required this.onWithdraw,
    required this.withdrawing,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'ImHere · 소중한 사람과 위치의 순간을 나눠요.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
        SizedBox(height: metrics.resolve(ImHereSpace.md)),
        ImHereButton(
          label: '로그아웃',
          tone: ImHereButtonTone.weak,
          expand: true,
          onPressed: onSignOut,
        ),
        SizedBox(height: metrics.resolve(ImHereSpace.xs)),
        ImHereButton(
          label: '회원 탈퇴',
          tone: ImHereButtonTone.danger,
          expand: true,
          loading: withdrawing,
          onPressed: withdrawing ? null : onWithdraw,
        ),
      ],
    );
  }
}
