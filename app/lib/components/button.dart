import 'package:flutter/material.dart';

import 'foundation.dart';
import 'icon.dart';
import 'pressable.dart';

/// Emphasis, highest first: [primary]/[neutral]/[danger] are solid and belong
/// to the one main action; [weak] is the medium-emphasis companion;
/// [secondary]/[quiet]/[ghost] are low emphasis. Brand color (primary and
/// secondary) is reserved for the service's core action.
enum ImHereButtonTone {
  primary,
  neutral,
  danger,
  weak,
  secondary,
  quiet,
  ghost,
}

enum ImHereButtonSize {
  lg(paddingX: 20, paddingY: 16, radius: 14, gap: 8, icon: 24),
  md(paddingX: 18, paddingY: 12, radius: 13, gap: 7, icon: 18),
  sm(paddingX: 16, paddingY: 8, radius: 12, gap: 6, icon: 16);

  const ImHereButtonSize({
    required this.paddingX,
    required this.paddingY,
    required this.radius,
    required this.gap,
    required this.icon,
  });
  final double paddingX;
  final double paddingY;
  final double radius;
  final double gap;
  final double icon;
}

/// Flat, shadow-free button. Colors change over 150ms and the button shrinks
/// slightly while pressed, instead of rippling.
/// Inactive buttons turn into a gray face with muted text; loading keeps the
/// active face and swaps the label for a spinner without changing width.
class ImHereButton extends StatelessWidget {
  const ImHereButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = ImHereButtonTone.primary,
    this.size = ImHereButtonSize.md,
    this.loading = false,
    this.expand = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ImHereButtonTone tone;
  final ImHereButtonSize size;
  final bool loading;
  final bool expand;
  final ImHereGlyph? icon;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final foreground = switch (tone) {
      ImHereButtonTone.primary => colors.onAction,
      ImHereButtonTone.neutral => colors.background,
      ImHereButtonTone.danger => colors.background,
      ImHereButtonTone.secondary => colors.action,
      ImHereButtonTone.weak ||
      ImHereButtonTone.quiet ||
      ImHereButtonTone.ghost => colors.text,
    };
    final solid = switch (tone) {
      ImHereButtonTone.primary ||
      ImHereButtonTone.neutral ||
      ImHereButtonTone.danger => true,
      _ => false,
    };
    final background = switch (tone) {
      ImHereButtonTone.primary => colors.action,
      ImHereButtonTone.neutral => colors.text,
      ImHereButtonTone.danger => colors.error,
      ImHereButtonTone.weak => colors.surfaceSubtle,
      _ => Colors.transparent,
    };
    final outline = switch (tone) {
      ImHereButtonTone.secondary => colors.action,
      ImHereButtonTone.quiet => colors.border,
      _ => null,
    };
    final inactive = !loading && onPressed == null;
    final shownBackground = inactive && solid ? colors.divider : background;
    final shownForeground = inactive ? colors.textMuted : foreground;
    final shownOutline = inactive && outline != null ? colors.divider : outline;
    final content = Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: metrics.resolve(size.gap),
      children: [
        if (icon != null) ImHereIcon(glyph: icon!, size: size.icon),
        Text(label, textAlign: TextAlign.center),
      ],
    );
    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        elevation: 0,
        animationDuration: ImHereMotion.colorOf(context),
        minimumSize: Size(metrics.touchTarget, metrics.touchTarget),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.resolve(size.paddingX),
          vertical: metrics.resolve(size.paddingY),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
        backgroundColor: shownBackground,
        foregroundColor: shownForeground,
        // Loading disables the press but keeps the active face.
        disabledBackgroundColor: shownBackground,
        disabledForegroundColor: shownForeground,
        overlayColor: shownForeground,
        side: shownOutline == null
            ? null
            : BorderSide(color: shownOutline, width: metrics.resolve(1)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.resolve(size.radius)),
        ),
      ),
      // Keep the label laid out (invisible) while loading so the button
      // does not change width when the spinner appears.
      child: loading
          ? Stack(
              alignment: Alignment.center,
              children: [
                Opacity(opacity: 0, child: content),
                Semantics(
                  label: '$label 처리 중',
                  liveRegion: true,
                  child: SizedBox(
                    width: metrics.resolve(20),
                    height: metrics.resolve(20),
                    child: CircularProgressIndicator(
                      strokeWidth: metrics.resolve(2),
                      color: shownForeground,
                    ),
                  ),
                ),
              ],
            )
          : content,
    );
    final pressable = ImHerePressable(
      enabled: onPressed != null && !loading,
      child: button,
    );
    return expand
        ? SizedBox(width: double.infinity, child: pressable)
        : pressable;
  }
}
