import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/component/feedback/app_snack_bar.dart';

void main() {
  testWidgets('FCM 배너는 상단 카드형으로 렌더링된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  AppSnackBar.showNotificationBanner(
                    context,
                    title: '새로운 친구 요청',
                    message: '홍길동님이 친구 요청을 보냈습니다.',
                  );
                },
                child: const Text('show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.byKey(const Key('app-notification-banner')), findsOneWidget);
    expect(find.text('새로운 친구 요청'), findsOneWidget);
    expect(find.text('홍길동님이 친구 요청을 보냈습니다.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    final bannerTopLeft = tester.getTopLeft(find.byKey(const Key('app-notification-banner')));
    expect(bannerTopLeft.dy, lessThan(120));

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.byKey(const Key('app-notification-banner')), findsNothing);
  });
}
