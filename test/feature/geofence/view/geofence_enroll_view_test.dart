import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/geofence/view/widget/radius_button.dart';
import 'package:iamhere/geofence/view/widget/radius_info_callout.dart';
import 'package:iamhere/geofence/view_model/geofence_enroll_view_model.dart';

void main() {
  group('GeofenceEnrollFormState 테스트', () {
    test('radiusInfoMessage는 250m에 대해 올바른 메시지를 반환해야 한다', () {
      // given
      final state = GeofenceEnrollFormState(radius: '250');

      // when
      final message = state.radiusInfoMessage;

      // then
      expect(message, '정확한 위치에서 알림을 보내드려요!');
    });

    test('radiusInfoMessage는 500m에 대해 올바른 메시지를 반환해야 한다', () {
      // given
      final state = GeofenceEnrollFormState(radius: '500');

      // when
      final message = state.radiusInfoMessage;

      // then
      expect(message, '적절한 범위에서 알림을 보내드려요!');
    });

    test('radiusInfoMessage는 1km에 대해 올바른 메시지를 반환해야 한다', () {
      // given
      final state = GeofenceEnrollFormState(radius: '1000');

      // when
      final message = state.radiusInfoMessage;

      // then
      expect(message, 'GPS가 정확하지 않아도 알람을 보낼 수 있어요!');
    });

    test('radiusInfoMessage는 반경이 없을 때 빈 문자열을 반환해야 한다', () {
      // given
      final state = GeofenceEnrollFormState(radius: '');

      // when
      final message = state.radiusInfoMessage;

      // then
      expect(message, '');
    });

    test('radiusInfoMessage는 지원하지 않는 반경에 대해 빈 문자열을 반환해야 한다', () {
      // given
      final state = GeofenceEnrollFormState(radius: '750');

      // when
      final message = state.radiusInfoMessage;

      // then
      expect(message, '');
    });
  });

  group('RadiusButton 위젯 테스트', () {
    testWidgets('RadiusButton이 올바른 텍스트를 표시해야 한다', (WidgetTester tester) async {
      // given & when
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(402, 874),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: RadiusButton(radius: 250, isSelected: false, onTap: () {}),
            ),
          ),
        ),
      );

      // then
      expect(find.text('250m'), findsOneWidget);
    });

    testWidgets('1km 버튼이 올바른 텍스트를 표시해야 한다', (WidgetTester tester) async {
      // given & when
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(402, 874),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: RadiusButton(radius: 1000, isSelected: false, onTap: () {}),
            ),
          ),
        ),
      );

      // then
      expect(find.text('1.0km'), findsOneWidget);
    });
  });

  group('RadiusInfoCallout 위젯 테스트', () {
    testWidgets('RadiusInfoCallout이 메시지를 표시해야 한다', (WidgetTester tester) async {
      // given
      const testMessage = '테스트 메시지';

      // when
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(402, 874),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(body: RadiusInfoCallout(message: testMessage)),
          ),
        ),
      );

      // then
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
