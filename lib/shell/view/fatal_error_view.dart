import 'package:flutter/material.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';

class ShellFatalErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const ShellFatalErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ShellStatusView(
      icon: Icons.error_outline_rounded,
      title: '화면을 불러오지 못했어요',
      message: '잠시 후 다시 시도해 주세요.',
      actionLabel: '다시 시도',
      onAction: onRetry,
    );
  }
}
