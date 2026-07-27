import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';

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
    await tester.pumpWidget(app(const ShellStatusView.splash()));
    expect(find.text('ImHere'), findsOneWidget);

    await tester.pumpWidget(app(ShellStatusView.offline(onRetry: () {})));
    expect(find.text('재시도'), findsOneWidget);

    await tester.pumpWidget(app(ShellStatusView.forceUpdate(onUpdate: () {})));
    expect(find.text('업데이트'), findsOneWidget);

    await tester.pumpWidget(app(ShellStatusView.fatalError(onRetry: () {})));
    expect(find.text('화면을 불러오지 못했어요.'), findsOneWidget);
  });

  testWidgets('renders status screens in dark mode', (tester) async {
    await tester.pumpWidget(
      app(ShellStatusView.offline(onRetry: () {}), mode: ThemeMode.dark),
    );

    final coloredBox = tester.widget<ColoredBox>(find.byType(ColoredBox).first);
    expect(coloredBox.color.computeLuminance(), lessThan(0.2));
  });
}
