import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/view/native_app_shell.dart';

void main() {
  test('maps app and release URLs to native page metadata', () {
    final main = NativeShellPage.fromLocation(
      'https://example.com/app/geofence',
    );
    expect(main.path, '/geofence');
    expect(main.title, '장소');
    expect(main.selectedTab, NativeShellTab.geofence);
    expect(main.showBackButton, isFalse);

    final detail = NativeShellPage.fromLocation(
      'https://example.com/app/releases/'
      '0123456789abcdef0123456789abcdef01234567/record/notifications/7',
    );
    expect(detail.path, '/record/notifications/7');
    expect(detail.title, '받은 알림 상세');
    expect(detail.selectedTab, NativeShellTab.record);
    expect(detail.showBackButton, isTrue);
  });

  testWidgets('renders Flutter title and five native navigation actions', (
    tester,
  ) async {
    String? destination;

    await tester.pumpWidget(
      MaterialApp(
        home: NativeAppShell(
          page: NativeShellPage.fromLocation('/friend'),
          onNavigate: (path) => destination = path,
          onBack: () {},
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.text('친구'), findsNWidgets(2));
    expect(find.byTooltip('뒤로'), findsNothing);
    expect(find.bySemanticsLabel('장소 추가'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('장소 추가'));
    expect(destination, '/geofence/message');
  });

  testWidgets('shows a native back action on a nested route', (tester) async {
    var backed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: NativeAppShell(
          page: NativeShellPage.fromLocation('/friend/add'),
          onNavigate: (_) {},
          onBack: () => backed = true,
          child: const SizedBox.expand(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('뒤로'));
    expect(backed, isTrue);
  });
}
