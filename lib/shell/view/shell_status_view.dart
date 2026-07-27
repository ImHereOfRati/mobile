import 'package:flutter/material.dart';

class ShellStatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;

  const ShellStatusView.splash({super.key})
    : icon = Icons.location_on_outlined,
      title = 'ImHere',
      message = '앱을 준비하고 있어요.',
      actionLabel = null,
      onAction = null,
      loading = true;

  const ShellStatusView.offline({super.key, required VoidCallback onRetry})
    : icon = Icons.wifi_off_rounded,
      title = '네트워크에 연결할 수 없어요.',
      message = '연결 상태를 확인한 뒤 다시 시도해 주세요.',
      actionLabel = '재시도',
      onAction = onRetry,
      loading = false;

  const ShellStatusView.forceUpdate({super.key, required VoidCallback onUpdate})
    : icon = Icons.system_update_rounded,
      title = '업데이트가 필요해요.',
      message = '계속 이용하려면 최신 버전으로 업데이트해 주세요.',
      actionLabel = '업데이트',
      onAction = onUpdate,
      loading = false;

  const ShellStatusView.fatalError({super.key, required VoidCallback onRetry})
    : icon = Icons.error_outline_rounded,
      title = '화면을 불러오지 못했어요.',
      message = '잠시 후 다시 시도해 주세요.',
      actionLabel = '재시도',
      onAction = onRetry,
      loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const CircularProgressIndicator()
                    else
                      Icon(icon, size: 36, color: theme.colorScheme.primary),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
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
