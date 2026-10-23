import 'package:flutter/material.dart';

import 'foundation.dart';

enum ImHereCalloutTone { neutral, warning, error }

/// Inline notice inside a screen. Not for transient feedback (use the
/// snackbar) or decisions (use the dialog).
class ImHereCallout extends StatelessWidget {
  const ImHereCallout({
    super.key,
    required this.text,
    this.title,
    this.tone = ImHereCalloutTone.neutral,
  });
  final String text;
  final String? title;
  final ImHereCalloutTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    final accent = switch (tone) {
      ImHereCalloutTone.neutral => colors.text,
      ImHereCalloutTone.warning => colors.warning,
      ImHereCalloutTone.error => colors.error,
    };
    return Semantics(
      container: true,
      liveRegion: tone == ImHereCalloutTone.error,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(metrics.resolve(ImHereSpace.md)),
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(metrics.resolve(ImHereRadius.md)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: textTheme.titleSmall?.copyWith(color: accent),
              ),
              SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
            ],
            Text(text, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Unread marker. Omit [count] for a plain dot; counts above 99 read "99+".
/// Pass the icon or button it belongs to as [child] and the badge sits on its
/// top-right corner, ringed in the background color so it never blends in.
class ImHereNotificationBadge extends StatelessWidget {
  const ImHereNotificationBadge({super.key, this.count, this.child});
  final int? count;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final c = count;
    if (c != null && c <= 0) return child ?? const SizedBox.shrink();
    final ring = BorderSide(
      color: child == null ? Colors.transparent : colors.background,
      width: metrics.resolve(2),
    );
    final text = c == null ? null : (c > 99 ? '99+' : '$c');
    final badge = text == null
        ? Container(
            width: metrics.resolve(10),
            height: metrics.resolve(10),
            decoration: BoxDecoration(
              color: colors.error,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(ring),
            ),
          )
        : Container(
            constraints: BoxConstraints(
              minWidth: metrics.resolve(20),
              minHeight: metrics.resolve(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: metrics.resolve(5)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.error,
              borderRadius: BorderRadius.circular(
                metrics.resolve(ImHereRadius.pill),
              ),
              border: Border.fromBorderSide(ring),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 11,
                height: 1,
                color: colors.background,
              ),
            ),
          );
    final label = text == null ? '새 소식' : '새 소식 $text개';
    if (child == null) {
      return Semantics(label: label, excludeSemantics: true, child: badge);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        Positioned(
          top: -metrics.resolve(text == null ? 4 : 8),
          right: -metrics.resolve(text == null ? 4 : 10),
          child: Semantics(label: label, excludeSemantics: true, child: badge),
        ),
      ],
    );
  }
}
