import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// 기록 개요의 한 묶음. 제목과 "전체 보기", 최근 항목 몇 건, 비었을 때의 안내.
///
/// 부모가 준 높이를 모두 채운다. 항목이 많으면 이 칸 안에서만 스크롤하므로,
/// 세 묶음을 같은 비율로 나눠 놓아도 서로 밀어내지 않는다.
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
        Expanded(
          child: children.isEmpty
              ? _EmptyHint(text: emptyTitle)
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: children.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                  itemBuilder: (_, index) => children[index],
                ),
        ),
      ],
    );
  }
}

/// 비어 있을 때 칸을 크게 차지하지 않도록, 칸 안에 맞춰 작게 보여 주는 안내.
class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = ImHereColors.of(context);
    final metrics = ImHereMetrics.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(metrics.resolve(ImHereRadius.lg)),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(metrics.resolve(ImHereSpace.sm)),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        ),
      ),
    );
  }
}
