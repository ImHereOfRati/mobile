import 'package:flutter/material.dart';

import 'foundation.dart';

/// Shrinks its child by a fixed 2px of height while pressed, so the feel is
/// the same for a small chip and a full-width row. The scale is derived from
/// the laid-out size: basis = max(height, width / 4, 24).
class ImHerePressable extends StatefulWidget {
  const ImHerePressable({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<ImHerePressable> createState() => _ImHerePressableState();
}

class _ImHerePressableState extends State<ImHerePressable> {
  static const _shrink = 2.0;
  double _scale = 1;

  void _press() {
    if (!widget.enabled) return;
    final size = context.size;
    if (size == null || size.isEmpty) return;
    final basis = [
      size.height,
      size.width / 4,
      24.0,
    ].reduce((a, b) => a > b ? a : b);
    setState(() => _scale = (basis - _shrink) / basis);
  }

  void _release() {
    if (_scale != 1) setState(() => _scale = 1);
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _press(),
    onPointerUp: (_) => _release(),
    onPointerCancel: (_) => _release(),
    child: AnimatedScale(
      scale: widget.enabled ? _scale : 1,
      duration: ImHereMotion.pressedOf(context),
      curve: ImHereMotion.pressedCurve,
      child: widget.child,
    ),
  );
}
