import 'package:flutter/material.dart';

import 'foundation.dart';
import 'icon.dart';
import 'pressable.dart';

/// [muted] marks a change of meaning (between sections; once or twice per
/// screen). [subtle] separates repeated items of the same kind (list rows).
/// Skip it after the last item.
enum ImHereDividerTone { muted, subtle }

/// Hairline separator. Decorative, so it uses the soft `divider` token.
class ImHereBorder extends StatelessWidget {
  const ImHereBorder({
    super.key,
    this.indent = 0,
    this.tone = ImHereDividerTone.muted,
  });
  final double indent;
  final ImHereDividerTone tone;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    return Divider(
      height: metrics.resolve(1),
      thickness: metrics.resolve(1),
      indent: metrics.resolve(indent),
      color: tone == ImHereDividerTone.muted
          ? ImHereColors.of(context).divider
          : ImHereColors.of(context).divider.withValues(alpha: 0.55),
    );
  }
}

/// Flat grouped container. Separates content by tone, not by shadow.
class ImHereSurface extends StatelessWidget {
  const ImHereSurface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = ImHereSpace.md,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final radius = BorderRadius.circular(metrics.resolve(ImHereRadius.lg));
    final card = Material(
      color: colors.surfaceSubtle,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.all(metrics.resolve(padding)),
          child: child,
        ),
      ),
    );
    return onTap == null ? card : ImHerePressable(child: card);
  }
}

class ImHereAsset extends StatelessWidget {
  const ImHereAsset({
    super.key,
    required this.glyph,
    required this.label,
    this.size = 44,
  });
  final ImHereGlyph glyph;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final extent = metrics.resolve(size);
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: extent,
          height: extent,
          decoration: BoxDecoration(
            border: Border.all(
              color: colors.divider,
              width: metrics.resolve(1),
            ),
            borderRadius: BorderRadius.circular(
              metrics.resolve(ImHereRadius.md),
            ),
          ),
          child: Center(
            child: ImHereIcon(
              glyph: glyph,
              color: colors.text,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
