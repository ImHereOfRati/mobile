import 'package:flutter/material.dart';

import 'foundation.dart';
import 'icon.dart';

/// Stand-in for content that is still loading. Match the final layout's
/// sizes so nothing jumps when the real content arrives.
class ImHereSkeleton extends StatefulWidget {
  const ImHereSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.circle = false,
  });
  final double? width;
  final double height;
  final bool circle;

  @override
  State<ImHereSkeleton> createState() => _ImHereSkeletonState();
}

class _ImHereSkeletonState extends State<ImHereSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
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
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
        child: Container(
          width: widget.width == null ? null : metrics.resolve(widget.width!),
          height: metrics.resolve(widget.height),
          decoration: BoxDecoration(
            color: colors.divider,
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget.circle
                ? null
                : BorderRadius.circular(metrics.resolve(ImHereRadius.sm)),
          ),
        ),
      ),
    );
  }
}

/// Fixed avatar sizes; do not use arbitrary pixel values.
enum ImHereAvatarSize {
  xs(24, 12),
  sm(32, 13),
  md(40, 14),
  lg(56, 18);

  const ImHereAvatarSize(this.extent, this.fontSize);
  final double extent;
  final double fontSize;
}

/// Person marker. Shows [image] when there is one, otherwise the first letter
/// of [name], otherwise a person glyph, so it is never an empty circle.
class ImHereAvatar extends StatelessWidget {
  const ImHereAvatar({
    super.key,
    required this.name,
    this.image,
    this.size = ImHereAvatarSize.md,
    this.ring = false,
  });
  final String name;
  final ImageProvider? image;
  final ImHereAvatarSize size;

  /// Outlines the avatar in the background color so it can overlap others.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final extent = metrics.resolve(size.extent);
    final Widget? fallback = image != null
        ? null
        : name.isEmpty
        ? ImHereIcon(
            glyph: ImHereGlyph.person,
            size: size.extent * 0.55,
            color: colors.textMuted,
          )
        : Text(
            name.characters.first,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: size.fontSize,
              height: 1,
              color: colors.text,
            ),
          );
    return Semantics(
      label: name.isEmpty ? '이름 없음' : name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: extent,
        height: extent,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          shape: BoxShape.circle,
          border: ring
              ? Border.all(color: colors.background, width: metrics.resolve(2))
              : null,
          image: image == null
              ? null
              : DecorationImage(image: image!, fit: BoxFit.cover),
        ),
        child: fallback,
      ),
    );
  }
}

/// Overlapping avatars for a group. Shows at most [max] and folds the rest
/// into a "+N" avatar.
class ImHereAvatarGroup extends StatelessWidget {
  const ImHereAvatarGroup({
    super.key,
    required this.names,
    this.size = ImHereAvatarSize.md,
    this.max = 3,
  });
  final List<String> names;
  final ImHereAvatarSize size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final colors = ImHereColors.of(context);
    final shown = names.take(max).toList();
    final rest = names.length - shown.length;
    final step = metrics.resolve(size.extent * 0.72);
    final count = shown.length + (rest > 0 ? 1 : 0);
    return Semantics(
      label: names.join(', '),
      excludeSemantics: true,
      child: SizedBox(
        width: metrics.resolve(size.extent) + step * (count - 1),
        height: metrics.resolve(size.extent),
        child: Stack(
          children: [
            for (var i = 0; i < shown.length; i++)
              Positioned(
                left: step * i,
                child: ImHereAvatar(name: shown[i], size: size, ring: true),
              ),
            if (rest > 0)
              Positioned(
                left: step * shown.length,
                child: Container(
                  width: metrics.resolve(size.extent),
                  height: metrics.resolve(size.extent),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.background,
                      width: metrics.resolve(2),
                    ),
                  ),
                  child: Text(
                    '+$rest',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: size.fontSize - 1,
                      height: 1,
                      color: colors.text,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
