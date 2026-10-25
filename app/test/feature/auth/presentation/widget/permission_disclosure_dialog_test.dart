import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/auth/view/widget/permission_disclosure_dialog.dart';
import 'package:iamhere/theme/imhere_theme.dart';

void main() {
  Future<void> showDisclosure(
    WidgetTester tester,
    Widget dialog,
    ValueNotifier<bool?> accepted,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ImHereAppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                accepted.value = await showDialog<bool>(
                  context: context,
                  builder: (_) => dialog,
                );
              },
              child: const Text('안내 열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('안내 열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('location popup explains background use and allows consent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final accepted = ValueNotifier<bool?>(null);
    await showDisclosure(tester, const LocationDisclosureDialog(), accepted);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('위치 권한이 필요해요'), findsOneWidget);
    expect(find.text('앱을 닫아도 위치 정보를 수집해요.'), findsOneWidget);
    expect(find.text('등록한 장소에 도착하거나 떠날 때, 선택한 친구에게 알려요.'), findsOneWidget);
    expect(
      tester.getRect(find.text('위치 허용하기')).top,
      lessThan(tester.getRect(find.text('취소')).top),
    );
    final smallTitleSize = tester
        .widget<Text>(find.text('위치 권한이 필요해요'))
        .style!
        .fontSize!;
    final smallBodySize = tester
        .widget<Text>(find.text('앱을 닫아도 위치 정보를 수집해요.'))
        .style!
        .fontSize!;
    tester.view.physicalSize = const Size(420, 800);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('위치 권한이 필요해요')).style!.fontSize,
      greaterThan(smallTitleSize),
    );
    expect(
      tester.widget<Text>(find.text('앱을 닫아도 위치 정보를 수집해요.')).style!.fontSize,
      greaterThan(smallBodySize),
    );
    await tester.tap(find.text('위치 허용하기'));
    await tester.pumpAndSettle();
    expect(accepted.value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification popup explains why alerts are needed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final accepted = ValueNotifier<bool?>(null);
    await showDisclosure(
      tester,
      const NotificationDisclosureDialog(),
      accepted,
    );
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('알림 권한이 필요해요'), findsOneWidget);
    expect(find.text('친구가 보낸 소식과 도착·이탈 알림을 받아요.'), findsOneWidget);
    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(accepted.value, isFalse);
    expect(tester.takeException(), isNull);
  });
}
