import 'package:flutter/material.dart';

import 'foundation.dart';

/// The ImHere wordmark, always set in 여기어때 잘난체 at one fixed size (24).
/// The typeface and size are fixed: the logo ignores the app text theme and
/// the system text scale, so it looks the same on every screen.
class ImHereLogo extends StatelessWidget {
  const ImHereLogo({super.key, this.color, this.caption});

  /// Family registered from `assets/fonts/Jalnan2.otf`.
  static const fontFamily = 'ImHereLogo';
  static const wordmark = 'ImHere';
  static const fontSize = 24.0;

  /// Defaults to the text color. Use the brand color only on a plain
  /// background.
  final Color? color;

  /// Word set after the wordmark in the same typeface and a muted color, for
  /// product names such as "ImHere Design".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    return Semantics(
      label: caption == null ? wordmark : '$wordmark $caption',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          text: wordmark,
          children: [
            if (caption != null)
              TextSpan(
                text: ' $caption',
                style: TextStyle(color: colors.textMuted),
              ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: metrics.resolve(fontSize),
          height: 1,
          letterSpacing: 0,
          color: color ?? colors.text,
        ),
      ),
    );
  }
}
