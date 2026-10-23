import 'package:flutter/material.dart';

import 'foundation.dart';

/// [neutral] is the default. Use [brand] only at an important first moment,
/// and [onDark] over a dimming overlay.
enum ImHereProgressTone { neutral, brand, onDark }

class ImHereProgress extends StatelessWidget {
  const ImHereProgress({
    super.key,
    this.label = '불러오는 중',
    this.size = 32,
    this.tone = ImHereProgressTone.neutral,
  });

  final String label;
  final double size;
  final ImHereProgressTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    return SizedBox.square(
      dimension: metrics.resolve(size),
      child: CircularProgressIndicator(
        strokeWidth: metrics.resolve(3),
        color: switch (tone) {
          ImHereProgressTone.neutral => colors.textMuted,
          ImHereProgressTone.brand => colors.action,
          ImHereProgressTone.onDark => Colors.white,
        },
        semanticsLabel: label,
      ),
    );
  }
}
