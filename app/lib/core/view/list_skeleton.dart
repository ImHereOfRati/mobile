import 'package:flutter/material.dart';
import 'package:iamhere/components/components.dart';

/// 목록 화면이 처음 불러오는 동안 보여 주는 자리 표시. 실제 행과 같은 크기로
/// 그려서 내용이 도착해도 화면이 튀지 않게 한다(SEED Loading: 예측 가능한 레이아웃에는
/// 스켈레톤).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    final metrics = ImHereMetrics.of(context);
    return Semantics(
      label: '불러오는 중',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          metrics.resolve(ImHereSpace.gutter),
          metrics.resolve(ImHereSpace.navToTitle),
          metrics.resolve(ImHereSpace.gutter),
          0,
        ),
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: EdgeInsets.only(bottom: metrics.resolve(ImHereSpace.md)),
              child: Row(
                children: [
                  const ImHereSkeleton(width: 40, height: 40, circle: true),
                  SizedBox(width: metrics.resolve(ImHereSpace.md)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ImHereSkeleton(width: 140, height: 16),
                        SizedBox(height: metrics.resolve(ImHereSpace.xs)),
                        const ImHereSkeleton(height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
