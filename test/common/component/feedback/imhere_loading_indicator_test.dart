import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';

void main() {
  testWidgets('ImHereLoadingIndicator는 ImHere 텍스트를 렌더링해야 함', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ImHereLoadingIndicator()),
        ),
      ),
    );

    expect(find.text('ImHere'), findsOneWidget);
  });
}
