import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// 눌러야 할 곳을 깜빡이는 테두리와 배경으로 가리킨다.
/// 모션 줄이기를 켠 기기에서는 깜빡이지 않고 강조 상태로 고정한다.
class PulsingHighlight extends StatefulWidget {
  final Widget child;

  const PulsingHighlight({super.key, required this.child});

  @override
  State<PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<PulsingHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduceMotion && _controller.isAnimating) return;
    _reduceMotion = reduce;
    if (reduce) {
      _controller
        ..stop()
        ..value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(
              colors.actionSubtle.withValues(alpha: 0.4),
              colors.actionSubtle,
              t,
            ),
            border: Border.all(
              color: colors.action.withValues(alpha: 0.35 + 0.65 * t),
              width: metrics.resolve(2),
            ),
            borderRadius: BorderRadius.circular(
              metrics.resolve(ImHereRadius.md),
            ),
          ),
          child: child,
        );
      },
    );
  }
}
