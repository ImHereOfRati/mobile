import 'package:flutter/material.dart';

import 'foundation.dart';

enum ImHereBadgeTone { action, success, warning, error, neutral }

enum ImHereBadgeStyle { strong, subtle }

/// Keep labels to two or three words and show at most one or two badges per
/// object.
enum ImHereBadgeSize { large, medium }

class ImHereBadge extends StatelessWidget {
  const ImHereBadge({
    super.key,
    required this.label,
    this.tone = ImHereBadgeTone.action,
    this.style = ImHereBadgeStyle.subtle,
    this.size = ImHereBadgeSize.large,
  });
  final String label;
  final ImHereBadgeTone tone;
  final ImHereBadgeStyle style;
  final ImHereBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final strong = switch (tone) {
      ImHereBadgeTone.action => colors.action,
      ImHereBadgeTone.success => colors.success,
      ImHereBadgeTone.warning => colors.warning,
      ImHereBadgeTone.error => colors.error,
      ImHereBadgeTone.neutral => colors.textMuted,
    };
    final isStrong = style == ImHereBadgeStyle.strong;
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.resolve(
              size == ImHereBadgeSize.large
                  ? ImHereSpace.xs
                  : ImHereSpace.xxs + 2,
            ),
            vertical: metrics.resolve(
              size == ImHereBadgeSize.large ? ImHereSpace.xxs : 2,
            ),
          ),
          decoration: BoxDecoration(
            color: isStrong ? strong : null,
            border: Border.all(color: strong, width: metrics.resolve(1)),
            borderRadius: BorderRadius.circular(
              metrics.resolve(ImHereRadius.pill),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isStrong ? colors.onAction : strong,
              fontSize: size == ImHereBadgeSize.large ? 13 : 12,
            ),
          ),
        ),
      ),
    );
  }
}
