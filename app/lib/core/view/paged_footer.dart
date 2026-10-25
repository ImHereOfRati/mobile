import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// 이어 불러오는 목록의 맨 아래. 다음 쪽을 읽는 동안에만 진행 표시를 보여 준다.
class PagedFooter extends StatelessWidget {
  const PagedFooter({super.key, required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    if (!loading) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: metrics.resolve(ImHereSpace.md)),
      child: const Center(child: ImHereProgress(size: 24)),
    );
  }
}
