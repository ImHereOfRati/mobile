import 'package:flutter/material.dart';

import 'button.dart';
import 'foundation.dart';
import 'icon.dart';

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

/// Use [onBack] to step back within a hierarchy and [onClose] to leave a
/// modal or standalone flow (input may be discarded). Pass only one.
class ImHereTopBar extends StatelessWidget {
  const ImHereTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.onClose,
    this.action,
  }) : assert(onBack == null || onClose == null);
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final gutter = SizedBox(width: metrics.resolve(ImHereSpace.gutter));
    Widget iconButton(String tooltip, VoidCallback onPressed, ImHereGlyph g) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: ImHereIcon(glyph: g),
          constraints: BoxConstraints(
            minWidth: metrics.touchTarget,
            minHeight: metrics.touchTarget,
          ),
        );
    return Material(
      color: ImHereColors.of(context).background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: metrics.resolve(ImHereSpace.xxs),
          ),
          child: Row(
            children: [
              if (onBack != null)
                iconButton('뒤로 가기', onBack!, ImHereGlyph.back)
              else if (onClose != null)
                iconButton('닫기', onClose!, ImHereGlyph.close)
              else
                gutter,
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              action ?? gutter,
            ],
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
