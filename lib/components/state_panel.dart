import 'package:flutter/material.dart';

import 'button.dart';
import 'foundation.dart';
import 'icon.dart';

/// [large] fills a whole screen; [medium] sits inside a card or section.
enum ImHereStateSize { large, medium }

/// Result states (empty, failure, done): one glyph, a title that says what
/// happened, one line on what to do, and at most two actions. For failures
/// pair a retry action with a way out.
class ImHereStatePanel extends StatelessWidget {
  const ImHereStatePanel({
    super.key,
    required this.glyph,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.size = ImHereStateSize.medium,
  });
  final ImHereGlyph glyph;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final ImHereStateSize size;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final large = size == ImHereStateSize.large;
    final column = Semantics(
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImHereIcon(
            glyph: glyph,
            size: large ? 40 : 28,
            color: colors.textMuted,
          ),
          SizedBox(height: metrics.resolve(ImHereSpace.md)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: large ? textTheme.titleLarge : textTheme.titleMedium,
          ),
          if (description != null) ...[
            SizedBox(height: metrics.resolve(ImHereSpace.xs)),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
          if (actionLabel != null || secondaryLabel != null) ...[
            SizedBox(height: metrics.resolve(ImHereSpace.lg)),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: metrics.resolve(ImHereSpace.xs),
              runSpacing: metrics.resolve(ImHereSpace.xs),
              children: [
                if (secondaryLabel != null)
                  ImHereButton(
                    label: secondaryLabel!,
                    onPressed: onSecondary,
                    tone: ImHereButtonTone.weak,
                  ),
                if (actionLabel != null)
                  ImHereButton(
                    label: actionLabel!,
                    onPressed: onAction,
                    tone: large
                        ? ImHereButtonTone.neutral
                        : ImHereButtonTone.weak,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.resolve(ImHereSpace.gutter),
          vertical: metrics.resolve(large ? ImHereSpace.xxl : ImHereSpace.xl),
        ),
        child: column,
      ),
    );
  }
}
