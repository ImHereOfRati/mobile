import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/record/view/widget/activity_section.dart';
import 'package:iamhere/theme/imhere_theme.dart';

void main() {
  Widget section(String title, {required int count}) => Expanded(
    child: ActivitySection(
      title: title,
      emptyTitle: '$title 없음',
      onShowAll: () {},
      children: [
        for (var i = 0; i < count; i++)
          SizedBox(height: 90, child: Text('$title $i')),
      ],
    ),
  );

  Future<void> pump(WidgetTester tester, {required double height}) async {
    tester.view.physicalSize = Size(400, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ImHereAppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              section('알림', count: 0),
              section('요청', count: 1),
              section('기록', count: 20),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('each section takes an equal third of the available height', (
    tester,
  ) async {
    await pump(tester, height: 900);

    final heights = [
      for (final title in ['알림', '요청', '기록'])
        tester
            .getSize(find.widgetWithText(ActivitySection, title).first)
            .height,
    ];

    // 비어 있든 항목이 많든 칸의 높이는 같다.
    expect(heights[0], closeTo(300, 0.5));
    expect(heights[1], closeTo(300, 0.5));
    expect(heights[2], closeTo(300, 0.5));
  });

  testWidgets('an empty section shows a small hint instead of a big panel', (
    tester,
  ) async {
    await pump(tester, height: 900);

    expect(find.text('알림 없음'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long list scrolls inside its own section', (tester) async {
    await pump(tester, height: 900);

    expect(find.text('기록 0'), findsOneWidget);
    expect(find.text('기록 19'), findsNothing);

    await tester.drag(find.text('기록 0'), const Offset(0, -2000));
    await tester.pump();

    expect(find.text('기록 19'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
