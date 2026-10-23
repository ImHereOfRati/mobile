import 'package:flutter/material.dart';

import 'foundation.dart';
import 'callout.dart';
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

/// Four destinations around a centered add action. The selected destination
/// gets a rule above it in addition to the color change, so state never
/// relies on color alone. Labels ignore the system text scale to protect the
/// content area; keep them short.
class ImHereNavigation extends StatelessWidget {
  const ImHereNavigation({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    required this.onAdd,
    this.addTooltip = '추가',
  }) : assert(items.length == 4),
       assert(index >= 0 && index < 4);
  final List<ImHereNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;
  final String addTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    return MediaQuery.withNoTextScaling(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: metrics.resolve(ImHereSpace.xs),
            ),
            child: Row(
              children: [
                _destination(context, 0),
                _destination(context, 1),
                Expanded(
                  child: Center(
                    child: IconButton.filled(
                      onPressed: onAdd,
                      tooltip: addTooltip,
                      icon: ImHereIcon(
                        glyph: ImHereGlyph.add,
                        color: colors.onAction,
                      ),
                      style: IconButton.styleFrom(
                        minimumSize: Size(
                          metrics.touchTarget,
                          metrics.touchTarget,
                        ),
                        backgroundColor: colors.action,
                        foregroundColor: colors.onAction,
                      ),
                    ),
                  ),
                ),
                _destination(context, 2),
                _destination(context, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _destination(BuildContext context, int itemIndex) {
    final selected = index == itemIndex;
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final item = items[itemIndex];
    final color = selected ? colors.text : colors.textMuted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.hasUpdate ? '${item.label}, 새 소식 있음' : item.label,
        excludeSemantics: true,
        onTap: () => onChanged(itemIndex),
        child: InkWell(
          onTap: () => onChanged(itemIndex),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: metrics.touchTarget),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: ImHereMotion.colorOf(context),
                  curve: ImHereMotion.easing,
                  width: metrics.resolve(24),
                  height: metrics.resolve(2),
                  color: selected ? colors.text : Colors.transparent,
                ),
                SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                item.hasUpdate
                    ? ImHereNotificationBadge(
                        child: ImHereIcon(glyph: item.glyph, color: color),
                      )
                    : ImHereIcon(glyph: item.glyph, color: color),
                SizedBox(height: metrics.resolve(ImHereSpace.xxs)),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
