import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/view/component/notification_overview_item.dart';
import 'package:iamhere/feature/record/view/notification_detail_view.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

void main() {
  final notification = NotificationEntity(
    title: '도착 알림',
    body: '홍길동님이 도착했습니다.',
    senderNickname: '홍길동',
    senderEmail: 'hong@example.com',
    path: '/record/notifications',
    createdAt: DateTime(2026, 6, 28, 10, 30),
  );

  Widget buildWidget() {
    final router = GoRouter(
      initialLocation: AppRoutes.recordNotifications,
      routes: [
        GoRoute(
          path: AppRoutes.recordNotifications,
          builder: (_, __) => Scaffold(
            body: NotificationOverviewItem(notification: notification),
          ),
        ),
        GoRoute(
          path: AppRoutes.recordNotificationDetail,
          builder: (_, state) => NotificationDetailView(
            notification: state.extra as NotificationEntity?,
          ),
        ),
      ],
    );

    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(402, 874),
        builder: (context, child) => MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('알림 항목을 탭하면 상세 페이지로 이동한다', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('도착 알림'));
    await tester.pumpAndSettle();

    expect(find.text('알림 상세'), findsOneWidget);
    expect(find.text('이동 경로'), findsOneWidget);
    expect(find.text('/record/notifications'), findsOneWidget);
  });

  testWidgets('상세 페이지는 알림 정보를 렌더링한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(402, 874),
          builder: (context, child) => MaterialApp(
            home: NotificationDetailView(notification: notification),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('도착 알림'), findsOneWidget);
    expect(find.text('홍길동 (hong@example.com)'), findsOneWidget);
    expect(find.text('/record/notifications'), findsOneWidget);
  });
}
