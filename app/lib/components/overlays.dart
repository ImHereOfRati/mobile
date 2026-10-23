import 'package:flutter/material.dart';

import 'button.dart';
import 'foundation.dart';

/// Short, non-blocking feedback after an action. One line, one optional
/// action (for example undo); it dismisses itself.
void showImHereSnackbar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = ImHereColors.of(context);
  final metrics = ImHereMetrics.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: colors.text,
        margin: EdgeInsets.all(metrics.resolve(ImHereSpace.gutter)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.resolve(ImHereRadius.md)),
        ),
        content: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.background),
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: colors.background,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}

/// Confirms a decision that needs an explicit answer. Resolves to `true` when
/// confirmed and `false` (or null when dismissed) otherwise. Set
/// [destructive] for deletions and other irreversible actions.
Future<bool?> showImHereDialog(
  BuildContext context, {
  required String title,
  String? description,
  required String confirmLabel,
  String cancelLabel = '취소',
  bool destructive = false,
}) {
  final colors = ImHereColors.of(context);
  final metrics = ImHereMetrics.of(context);
  final textTheme = Theme.of(context).textTheme;
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.all(metrics.resolve(ImHereSpace.gutter)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.resolve(ImHereRadius.lg)),
      ),
      child: Padding(
        padding: EdgeInsets.all(metrics.resolve(ImHereSpace.lg)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: textTheme.titleMedium),
            ),
            if (description != null) ...[
              SizedBox(height: metrics.resolve(ImHereSpace.xs)),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ],
            SizedBox(height: metrics.resolve(ImHereSpace.lg)),
            Row(
              children: [
                // Both actions always share the width equally.
                Expanded(
                  child: ImHereButton(
                    label: cancelLabel,
                    tone: ImHereButtonTone.weak,
                    expand: true,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                SizedBox(width: metrics.resolve(ImHereSpace.xs)),
                Expanded(
                  child: ImHereButton(
                    label: confirmLabel,
                    tone: destructive
                        ? ImHereButtonTone.danger
                        : ImHereButtonTone.neutral,
                    expand: true,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Modal sheet for a secondary task that keeps the user on the screen.
Future<T?> showImHereSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  final colors = ImHereColors.of(context);
  final metrics = ImHereMetrics.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: colors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(metrics.resolve(ImHereRadius.sheet)),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.xs),
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: metrics.resolve(36),
                height: metrics.resolve(4),
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(
                    metrics.resolve(ImHereRadius.pill),
                  ),
                ),
              ),
            ),
            SizedBox(height: metrics.resolve(ImHereSpace.md)),
            Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: metrics.resolve(ImHereSpace.md)),
            Flexible(child: builder(sheetContext)),
          ],
        ),
      ),
    ),
  );
}
