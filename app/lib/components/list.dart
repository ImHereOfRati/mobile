import 'package:flutter/material.dart';

import 'foundation.dart';
import 'icon.dart';

class ImHereListRow extends StatelessWidget {
  const ImHereListRow({
    super.key,
    required this.title,
    this.description,
    this.leading,
    this.trailing,
    this.onTap,
    this.alignTop = false,
  });
  final String title;
  final String? description;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      onTap: onTap,
      titleAlignment: alignTop
          ? ListTileTitleAlignment.top
          : ListTileTitleAlignment.center,
      // 행은 강조가 아니라 내용이다. 굵기를 더하지 않고 본문 서체를 쓴다.
      titleTextStyle: textTheme.bodyLarge,
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.textMuted,
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: metrics.resolve(ImHereSpace.xs),
      ),
      horizontalTitleGap: metrics.resolve(ImHereSpace.md),
      minTileHeight: metrics.touchTarget,
      leading: leading,
      title: Text(title),
      subtitle: description == null ? null : Text(description!),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : ImHereIcon(
                  glyph: ImHereGlyph.chevron,
                  size: 20,
                  color: colors.textMuted,
                )),
    );
  }
}

class ImHereListHeader extends StatelessWidget {
  const ImHereListHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    final heading = Semantics(
      header: true,
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
    final action = actionLabel == null
        ? null
        : TextButton(onPressed: onAction, child: Text(actionLabel!));
    return Padding(
      padding: EdgeInsets.symmetric(vertical: metrics.resolve(ImHereSpace.xs)),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth < metrics.resolve(240)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, ?action],
              )
            : Row(
                children: [
                  Expanded(child: heading),
                  ?action,
                ],
              ),
      ),
    );
  }
}

class ImHereParagraph extends StatelessWidget {
  const ImHereParagraph({super.key, required this.text, this.muted = false});
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: muted ? ImHereColors.of(context).textMuted : null,
    ),
  );
}
