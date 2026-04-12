import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage buildPageWithBottomUpTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),

    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // 시작 지점: 화면 아래 (y=1.0)
      const end = Offset.zero; // 도착 지점: 화면 중앙 (y=0.0)

      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: Curves.easeOut)); // 부드러운 전환 커브 적용

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
