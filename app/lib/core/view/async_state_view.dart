import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/view/list_skeleton.dart';

/// 불러오는 중(스켈레톤), 실패(다시 시도), 성공 세 상태를 같은 모양으로 보여 준다.
///
/// 실패는 무슨 일이 있었는지와 다음에 할 일(다시 시도)을 함께 알린다.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.onRetry,
    required this.errorTitle,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final String errorTitle;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const ListSkeleton(),
      error: (_, __) => ImHereStatePanel(
        glyph: ImHereGlyph.close,
        title: errorTitle,
        description: '연결을 확인하고 다시 시도해 주세요.',
        actionLabel: '다시 시도',
        onAction: onRetry,
        size: ImHereStateSize.large,
      ),
      data: builder,
    );
  }
}
