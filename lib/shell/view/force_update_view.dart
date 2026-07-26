import 'package:flutter/material.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';

class ShellForceUpdateView extends StatelessWidget {
  final VoidCallback onUpdate;

  const ShellForceUpdateView({super.key, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ShellStatusView(
      icon: Icons.system_update_rounded,
      title: '업데이트가 필요해요',
      message: '안전한 서비스 이용을 위해 최신 버전으로 업데이트해 주세요.',
      actionLabel: '업데이트하기',
      onAction: onUpdate,
    );
  }
}
