import 'dart:async';

import 'package:flutter/material.dart';

/// A full-viewport scene that stays pinned while the user scrolls through
/// [scrollExtent] extra pixels. [builder] receives that scroll as `progress`
/// (0 → 1). Progress comes from the sliver constraints, so it is computed in
/// the same layout pass as the scroll and never lags a frame.
///
/// Each scene lives in its own [SliverMainAxisGroup], so its pinned header
/// scrolls away with the scene instead of stacking up behind the next one.
class SceneSliver extends StatelessWidget {
  const SceneSliver({
    super.key,
    required this.viewportHeight,
    required this.scrollExtent,
    required this.background,
    required this.builder,
  });

  final double viewportHeight;
  final double scrollExtent;
  final Color background;
  final Widget Function(BuildContext context, double progress) builder;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverLayoutBuilder(
        builder: (context, constraints) => SliverPersistentHeader(
          pinned: true,
          delegate: _SceneDelegate(
            height: viewportHeight,
            background: background,
            child: builder(
              context,
              (constraints.scrollOffset / scrollExtent).clamp(0.0, 1.0),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: scrollExtent)),
    ],
  );
}

class _SceneDelegate extends SliverPersistentHeaderDelegate {
  _SceneDelegate({
    required this.height,
    required this.background,
    required this.child,
  });

  final double height;
  final Color background;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: background,
    child: ClipRect(child: child),
  );

  @override
  bool shouldRebuild(_SceneDelegate old) => true;
}

/// Maps the slice [begin, end] of [t] onto 0 → 1.
double span(double t, double begin, double end) =>
    ((t - begin) / (end - begin)).clamp(0.0, 1.0);

/// Ease-out used for scroll-driven motion.
double easeOut(double t) => Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));

/// Builds with `visible == true` once the widget first scrolls into view.
class RevealBuilder extends StatefulWidget {
  const RevealBuilder({
    super.key,
    required this.builder,
    this.delay = Duration.zero,
  });

  final Widget Function(BuildContext context, bool visible) builder;
  final Duration delay;

  @override
  State<RevealBuilder> createState() => _RevealBuilderState();
}

class _RevealBuilderState extends State<RevealBuilder> {
  ScrollPosition? _position;
  Timer? _timer;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_check);
      _position = next;
      next?.addListener(_check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _timer?.cancel();
    super.dispose();
  }

  void _check() {
    if (!mounted || _visible || _timer != null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    if (top > MediaQuery.sizeOf(context).height * 0.92) return;
    void show() {
      if (mounted) setState(() => _visible = true);
    }

    if (widget.delay == Duration.zero) {
      show();
    } else {
      _timer = Timer(widget.delay, show);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _visible);
}

/// Fade + rise when scrolled into view.
class Reveal extends StatelessWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.rise = 0.08,
  });

  final Widget child;
  final Duration delay;
  final double rise;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 600);
    return RevealBuilder(
      delay: delay,
      builder: (context, visible) => AnimatedSlide(
        duration: duration,
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : Offset(0, rise),
        child: AnimatedOpacity(
          duration: duration,
          curve: Curves.easeOut,
          opacity: visible ? 1 : 0,
          child: child,
        ),
      ),
    );
  }
}
