import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/shell/view/native_app_shell.dart';
import 'package:iamhere/theme/imhere_theme.dart';

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

  Widget shell(
    String location, {
    ValueChanged<String>? onNavigate,
    VoidCallback? onBack,
  }) => MaterialApp(
    theme: ImHereAppTheme.light,
    home: NativeAppShell(
      page: NativeShellPage.fromLocation(location),
      onNavigate: onNavigate ?? (_) {},
      onBack: onBack ?? () {},
      child: const SizedBox.expand(),
    ),
  );

  testWidgets('renders the app header and four navigation destinations', (
    tester,
  ) async {
    String? destination;

    await tester.pumpWidget(
      shell('/friend', onNavigate: (path) => destination = path),
    );

    expect(find.byType(ImHereAppHeader), findsOneWidget);
    expect(find.byType(ImHereNavigation), findsOneWidget);
    for (final label in ['장소', '친구', '기록', '설정']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.byTooltip('뒤로 가기'), findsNothing);

    await tester.tap(find.bySemanticsLabel('기록'));
    expect(destination, '/record');

    await tester.tap(find.byTooltip('알림'));
    expect(destination, '/record/notifications');
  });

  testWidgets('shows a title bar with a back action on a nested route', (
    tester,
  ) async {
    var backed = false;

    await tester.pumpWidget(shell('/friend/add', onBack: () => backed = true));

    expect(find.byType(ImHereTopBar), findsOneWidget);
    expect(find.text('친구 추가'), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로 가기'));
    expect(backed, isTrue);
  });

  testWidgets('hides navigation on routes outside the four tabs', (
    tester,
  ) async {
    await tester.pumpWidget(shell('/user-permission'));

    expect(find.byType(ImHereNavigation), findsNothing);
  });
}
