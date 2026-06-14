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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final gradient = LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.25),
            cs.primary,
            cs.primary.withValues(alpha: 0.25),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-2.0 + t * 4, 0),
          end: Alignment(-1.0 + t * 4, 0),
        );
        return ShaderMask(
          shaderCallback: (r) => gradient.createShader(r),
          blendMode: BlendMode.srcIn,
          child: Image.asset(
            'assets/images/imhere_wordmark.png',
            height: widget.height,
          ),
        );
      },
    );
  }
}
