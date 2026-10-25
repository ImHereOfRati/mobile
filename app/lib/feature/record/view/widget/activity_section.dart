import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// 기록 개요의 한 묶음. 제목과 "전체 보기", 최근 항목 몇 건, 비었을 때의 안내.
class ActivitySection extends StatelessWidget {
  final String title;
  final String emptyTitle;
  final VoidCallback onShowAll;
  final List<Widget> children;

  const ActivitySection({
    super.key,
    required this.title,
    required this.emptyTitle,
    required this.onShowAll,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImHereListHeader(
          title: title,
          actionLabel: '전체 보기',
          onAction: onShowAll,
        ),
        if (children.isEmpty)
          ImHereStatePanel(glyph: ImHereGlyph.history, title: emptyTitle)
        else
          for (final child in children) ...[
            child,
            SizedBox(height: metrics.resolve(ImHereSpace.xs)),
          ],
      ],
    );
  }
}
