import 'package:flutter/material.dart';

import 'button.dart';
import 'foundation.dart';
import 'icon.dart';
import 'logo.dart';

/// The only top bar the app uses: the [ImHereLogo], an optional notification
/// icon, and a bottom divider. Hide the icon on screens that have no
/// notifications to open (for example before signing in).
class ImHereAppHeader extends StatelessWidget {
  const ImHereAppHeader({
    super.key,
    this.onNotificationTap,
    this.showNotification = true,
  });

  final VoidCallback? onNotificationTap;
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: metrics.touchTarget),
          child: Padding(
            padding: EdgeInsets.only(
              left: metrics.resolve(ImHereSpace.gutter),
              right: metrics.resolve(ImHereSpace.xs),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const ImHereLogo(scale: 5 / 7),
                if (showNotification)
                  IconButton(
                    tooltip: '알림',
                    onPressed: onNotificationTap,
                    icon: const ImHereIcon(glyph: ImHereGlyph.bell),
                    constraints: BoxConstraints(
                      minWidth: metrics.touchTarget,
                      minHeight: metrics.touchTarget,
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

/// Line tabs. Up to five labels share the width equally; from six on they
/// hug their text and scroll, so long labels are never squeezed.
class ImHereTabBar extends StatelessWidget {
  const ImHereTabBar({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  static const _hugFrom = 6;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final hug = labels.length >= _hugFrom;
    final tabs = [
      for (var i = 0; i < labels.length; i++)
        hug
            ? Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.resolve(ImHereSpace.xxs),
                ),
                child: _tab(context, i, hug: true),
              )
            : Expanded(child: _tab(context, i)),
    ];
    return hug
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: metrics.resolve(ImHereSpace.gutter),
            ),
            child: Row(children: tabs),
          )
        : Row(children: tabs);
  }

  Widget _tab(BuildContext context, int i, {bool hug = false}) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final selected = i == index;
    return Semantics(
      button: true,
      selected: selected,
      label: labels[i],
      excludeSemantics: true,
      onTap: () => onChanged(i),
      child: InkWell(
        onTap: () => onChanged(i),
        child: AnimatedContainer(
          duration: ImHereMotion.colorOf(context),
          curve: ImHereMotion.easing,
          constraints: BoxConstraints(minHeight: metrics.touchTarget),
          padding: EdgeInsets.symmetric(
            horizontal: metrics.resolve(hug ? ImHereSpace.md : ImHereSpace.xs),
            vertical: metrics.resolve(ImHereSpace.xs),
          ),
          alignment: hug ? null : Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? colors.text : colors.divider,
                width: metrics.resolve(selected ? 2 : 1),
              ),
            ),
          ),
          child: Text(
            labels[i],
            maxLines: hug ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? colors.text : colors.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed footer: a hairline spans the screen, content keeps the gutter.
/// With two actions both share the width equally.
class ImHereBottomAction extends StatelessWidget {
  const ImHereBottomAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: metrics.resolve(ImHereSpace.md)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            metrics.resolve(ImHereSpace.gutter),
            metrics.resolve(ImHereSpace.sm),
            metrics.resolve(ImHereSpace.gutter),
            0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final primary = ImHereButton(
                label: label,
                onPressed: onPressed,
                loading: loading,
                size: ImHereButtonSize.lg,
                expand: true,
              );
              if (secondaryLabel == null) return primary;
              final secondary = ImHereButton(
                label: secondaryLabel!,
                onPressed: onSecondaryPressed,
                tone: ImHereButtonTone.weak,
                size: ImHereButtonSize.lg,
                expand: true,
              );
              if (constraints.maxWidth < metrics.resolve(280)) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    primary,
                    SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                    secondary,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: secondary),
                  SizedBox(width: metrics.resolve(ImHereSpace.xs)),
                  Expanded(child: primary),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
