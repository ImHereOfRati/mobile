import 'dart:ui';

import 'package:flutter/material.dart';

import 'callout.dart';
import 'foundation.dart';
import 'icon.dart';

@immutable
class ImHereNavItem {
  const ImHereNavItem({
    required this.glyph,
    required this.label,
    this.hasUpdate = false,
  });
  final ImHereGlyph glyph;
  final String label;

  /// Shows a dot for new content. Mark at most one destination at a time.
  final bool hasUpdate;
}

/// Bottom navigation bar in an Apple-style glass look: a blurred translucent
/// bar holding a floating capsule. The capsule has a hairline edge and a soft
/// shadow so its boundary stays visible on any page color, and the selected
/// destination is marked by a brand-tinted pill.
class ImHereNavigation extends StatelessWidget {
  const ImHereNavigation({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  }) : assert(items.length == 4),
       assert(index >= 0 && index < 4);

  final List<ImHereNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return MediaQuery.withNoTextScaling(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.78),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.resolve(ImHereSpace.md),
                  vertical: metrics.resolve(ImHereSpace.xs),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceSubtle,
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.7),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(
                      metrics.resolve(ImHereRadius.pill),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: metrics.resolve(18),
                        offset: Offset(0, metrics.resolve(4)),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(metrics.resolve(3.5)),
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _destination(context, i, duration),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int itemIndex, Duration duration) {
    final selected = index == itemIndex;
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final item = items[itemIndex];
    final color = selected ? colors.action : colors.textMuted;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.hasUpdate ? '${item.label}, 새 소식 있음' : item.label,
        excludeSemantics: true,
        onTap: () => onChanged(itemIndex),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(itemIndex),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(
              minHeight: metrics.touchTarget * 5 / 7 * 1.15,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: metrics.resolve(ImHereSpace.xs),
              vertical: metrics.resolve(4),
            ),
            decoration: BoxDecoration(
              // 선택된 곳은 브랜드 색 배경으로 구분한다. 테두리를 두지 않아
              // 선택이 바뀔 때 안쪽 크기가 달라져 흔들리는 일도 없다.
              color: selected ? colors.actionSubtle : Colors.transparent,
              borderRadius: BorderRadius.circular(
                metrics.resolve(ImHereRadius.pill),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  scale: selected ? 1.08 : 1.0,
                  child: item.hasUpdate
                      ? ImHereNotificationBadge(
                          child: ImHereIcon(
                            glyph: item.glyph,
                            color: color,
                            size: 22,
                          ),
                        )
                      : ImHereIcon(glyph: item.glyph, color: color, size: 22),
                ),
                SizedBox(height: metrics.resolve(3)),
                AnimatedDefaultTextStyle(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  style:
                      (Theme.of(context).textTheme.labelSmall ??
                              const TextStyle(fontSize: 11))
                          .copyWith(
                            fontSize: metrics.resolve(11),
                            height: 1.1,
                            color: color,
                            // 굵기를 바꾸면 글자 폭이 달라져 라벨이 흔들린다.
                            fontWeight: FontWeight.w500,
                          ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
