import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/view/fatal_error_view.dart';
import 'package:iamhere/shell/view/force_update_view.dart';
import 'package:iamhere/shell/view/offline_view.dart';
import 'package:iamhere/shell/view/splash_view.dart';

void main() {
  Widget app(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: mode,
      home: child,
    );
  }

  testWidgets('renders all four native shell states', (tester) async {
    await tester.pumpWidget(app(const ShellSplashView()));
    expect(find.text('ImHere'), findsOneWidget);

    await tester.pumpWidget(app(ShellOfflineView(onRetry: () {})));
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.pumpWidget(app(ShellForceUpdateView(onUpdate: () {})));
    expect(find.text('업데이트하기'), findsOneWidget);

    await tester.pumpWidget(app(ShellFatalErrorView(onRetry: () {})));
    expect(find.text('화면을 불러오지 못했어요'), findsOneWidget);
  });

  testWidgets('renders status screens in dark mode', (tester) async {
    await tester.pumpWidget(
      app(ShellOfflineView(onRetry: () {}), mode: ThemeMode.dark),
    );

    final coloredBox = tester.widget<ColoredBox>(find.byType(ColoredBox).first);
    expect(coloredBox.color.computeLuminance(), lessThan(0.2));
  });
}
