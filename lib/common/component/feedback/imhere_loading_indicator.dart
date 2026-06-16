import 'package:flutter/material.dart';

class ImHereLoadingIndicator extends StatefulWidget {
  const ImHereLoadingIndicator({super.key, this.height = 28.0});

  final double height;

  @override
  State<ImHereLoadingIndicator> createState() =>
      _ImHereLoadingIndicatorState();
}

class _ImHereLoadingIndicatorState extends State<ImHereLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      fontFamily: 'GmarketSans',
      fontSize: widget.height * 0.9,
      fontWeight: FontWeight.w700,
      color: cs.primary,
      letterSpacing: -0.6,
      height: 1.0,
    );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final opacity = 0.45 + (_ctrl.value * 0.55);
        return SizedBox(
          height: widget.height,
          child: Center(
            child: Opacity(
              opacity: opacity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('ImHere', style: textStyle),
              ),
            ),
          ),
        );
      },
    );
  }
}
