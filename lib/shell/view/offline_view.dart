import 'package:flutter/material.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';

class ShellOfflineView extends StatelessWidget {
  final VoidCallback onRetry;

  const ShellOfflineView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ShellStatusView(
      icon: Icons.wifi_off_rounded,
      title: '인터넷에 연결할 수 없어요',
      message: '연결 상태를 확인한 뒤 다시 시도해 주세요.\n자동 전송 기능은 계속 동작합니다.',
      actionLabel: '다시 시도',
      onAction: onRetry,
    );
  }
}
