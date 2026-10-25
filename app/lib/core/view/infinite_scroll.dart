import 'package:flutter/widgets.dart';

/// 스크롤이 끝에 가까워지면 [onLoadMore]를 부른다. 중복 요청은 부르는 쪽(뷰모델)이
/// 막는다.
class InfiniteScroll extends StatelessWidget {
  const InfiniteScroll({
    super.key,
    required this.hasNext,
    required this.onLoadMore,
    required this.child,
    this.threshold = 240,
  });

  final bool hasNext;
  final VoidCallback onLoadMore;
  final Widget child;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (hasNext &&
            notification.depth == 0 &&
            notification.metrics.extentAfter < threshold) {
          onLoadMore();
        }
        return false;
      },
      child: child,
    );
  }
}
