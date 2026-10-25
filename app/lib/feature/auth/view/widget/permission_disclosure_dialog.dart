import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/auth/view/widget/background_location_disclosure_details.dart';

class LocationDisclosureDialog extends StatelessWidget {
  const LocationDisclosureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return _PermissionDialog(
      glyph: ImHereGlyph.place,
      title: '위치 권한이 필요해요',
      description: const BackgroundLocationDisclosureDetails(),
      confirmLabel: '위치 허용하기',
      dismissLabel: '취소',
    );
  }
}

class NotificationDisclosureDialog extends StatelessWidget {
  const NotificationDisclosureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PermissionDialog(
      glyph: ImHereGlyph.bell,
      title: '알림 권한이 필요해요',
      description: Text('친구가 보낸 소식과 도착·이탈 알림을 받아요.'),
      confirmLabel: '알림 허용하기',
      dismissLabel: '나중에',
    );
  }
}

class _PermissionDialog extends StatelessWidget {
  const _PermissionDialog({
    required this.glyph,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.dismissLabel,
  });

  final ImHereGlyph glyph;
  final String title;
  final Widget description;
  final String confirmLabel;
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final theme = Theme.of(context);
    final textScale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.1);
    TextStyle? scaled(TextStyle? style) => style?.copyWith(
      fontSize: style.fontSize == null ? null : style.fontSize! * textScale,
    );
    final textTheme = theme.textTheme.copyWith(
      titleLarge: scaled(theme.textTheme.titleLarge),
      bodyLarge: scaled(theme.textTheme.bodyLarge),
      bodyMedium: scaled(theme.textTheme.bodyMedium),
      labelLarge: scaled(theme.textTheme.labelLarge),
    );

    return Theme(
      data: theme.copyWith(textTheme: textTheme),
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: metrics.resolve(ImHereSpace.md),
          vertical: metrics.resolve(ImHereSpace.lg),
        ),
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            metrics.resolve(ImHereRadius.sheet),
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(metrics.resolve(ImHereSpace.lg)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: metrics.resolve(48),
                    height: metrics.resolve(48),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.actionSubtle,
                      borderRadius: BorderRadius.circular(
                        metrics.resolve(ImHereRadius.md),
                      ),
                    ),
                    child: ImHereIcon(glyph: glyph, color: colors.action),
                  ),
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.md)),
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(color: colors.text),
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.sm)),
                DefaultTextStyle.merge(
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                    height: 1.5,
                  ),
                  child: description,
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.lg)),
                ImHereButton(
                  label: confirmLabel,
                  size: ImHereButtonSize.lg,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                ImHereButton(
                  label: dismissLabel,
                  tone: ImHereButtonTone.ghost,
                  expand: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
