import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/component/navigation/default_view/navigation_bar/navigation_tabs.dart';
import 'package:iamhere/common/component/navigation/default_view/navigation_bar/tab_item.dart';

void main() {
  Widget createWidget({required NavTab tab, required bool isSelected, required VoidCallback onTap}) {
    return ScreenUtilInit(
      designSize: const Size(402, 874),
      builder: (_, __) {
        return MaterialApp(
          home: Material(
            child: TabItem(
              tab: tab,
              isSelected: isSelected,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  final tab = NavTab(
    route: '/friend',
    label: '친구',
    icon: Icons.people_outline,
    activeIcon: Icons.people,
  );

  testWidgets('선택 상태면 active icon을 보여준다', (tester) async {
    await tester.pumpWidget(
      createWidget(tab: tab, isSelected: true, onTap: () {}),
    );

    expect(find.byIcon(Icons.people), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsNothing);
    expect(find.text('친구'), findsOneWidget);
  });

  testWidgets('탭하면 전달받은 콜백을 호출한다', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      createWidget(tab: tab, isSelected: false, onTap: () => tapped = true),
    );

    await tester.tap(find.byType(TabItem));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
