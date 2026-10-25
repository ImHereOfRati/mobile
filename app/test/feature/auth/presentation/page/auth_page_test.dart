import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/feature/auth/viewmodel/sign_in_controller.dart';
import 'package:iamhere/feature/auth/view/page/auth_page.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/theme/imhere_theme.dart';
import 'package:mockito/mockito.dart';

class _SocialLoginServiceMock extends Mock implements SocialLoginService {}

void main() {
  Future<void> pumpAuthPage(
    WidgetTester tester,
    Size size, {
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final coordinator = _SocialLoginServiceMock();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          signInControllerProvider(
            coordinator,
          ).overrideWith(SignInController.new),
        ],
        child: MaterialApp(
          theme: ImHereAppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: child!,
          ),
          home: AuthPage(
            authLoginCoordinator: coordinator,
            onAuthenticated: () {},
            requestLocationPermission: () async {},
          ),
        ),
      ),
    );
  }

  testWidgets('shows the service value and labeled login actions', (
    tester,
  ) async {
    await pumpAuthPage(tester, const Size(360, 800));

    expect(find.text('출발할 때, 도착할 때\n연락은 ImHere가 대신 보낼게요'), findsOneWidget);
    expect(find.text('카카오로 계속하기'), findsOneWidget);
    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('allows scrolling on a small screen without layout errors', (
    tester,
  ) async {
    await pumpAuthPage(tester, const Size(320, 568));
    await tester.scrollUntilVisible(
      find.text('Google로 계속하기'),
      150,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Google로 계속하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('centers the rotating content between copy and login', (
    tester,
  ) async {
    await pumpAuthPage(tester, const Size(360, 800));

    final description = tester.getRect(
      find.text('알리고 싶은 장소와 반경만 정해두세요.\n앱을 꺼둬도 필요한 순간에 자동으로 보내요.'),
    );
    final showcase = tester.getRect(find.byKey(const Key('auth-showcase')));
    final preview = tester.getRect(find.byKey(const Key('auth-story')));
    final login = tester.getRect(find.text('간편하게 시작하기'));

    expect(showcase.top, greaterThan(description.bottom));
    expect(showcase.bottom, lessThan(login.top));
    expect(showcase.center.dx, closeTo(180, 1));
    expect(
      showcase.center.dy,
      closeTo((description.bottom + login.top) / 2, 1),
    );
    expect(preview.top, greaterThan(description.bottom));
    expect(preview.bottom, lessThan(login.top));
  });

  testWidgets('alternates the statement and detection every five seconds', (
    tester,
  ) async {
    await pumpAuthPage(tester, const Size(360, 800));

    expect(
      find.text(
        '자고 있어서, 운전 중이라서,\n깜빡해서.\n연락을 못 한 적, 있죠?\n그 연락, ImHere가 대신 보낼게요.',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
    expect(
      find.text(
        '자고 있어서, 운전 중이라서,\n깜빡해서.\n연락을 못 한 적, 있죠?\n그 연락, ImHere가 대신 보낼게요.',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('우리 집까지 · 반경 300m'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        '자고 있어서, 운전 중이라서,\n깜빡해서.\n연락을 못 한 적, 있죠?\n그 연락, ImHere가 대신 보낼게요.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a shrinking detection distance in the second scene', (
    tester,
  ) async {
    await pumpAuthPage(tester, const Size(360, 800));

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('우리 집까지 · 반경 300m'), findsOneWidget);
    final distance = find.byKey(const Key('auth-detect-distance'));
    final before = int.parse(
      tester.widget<Text>(distance).data!.split(' ').first,
    );

    await tester.pump(const Duration(milliseconds: 400));
    final after = int.parse(
      tester.widget<Text>(distance).data!.split(' ').first,
    );
    expect(after, lessThan(before));

    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.byKey(const Key('auth-arrival-notification')), findsOneWidget);
    expect(find.text('우리 집 도착'), findsOneWidget);
    expect(find.text('엄마에게 도착을 알렸어요'), findsOneWidget);
    expect(find.text('문자 전송 완료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the example still when animations are disabled', (
    tester,
  ) async {
    await pumpAuthPage(tester, const Size(360, 800), disableAnimations: true);

    await tester.pump(const Duration(seconds: 12));
    expect(
      find.text(
        '자고 있어서, 운전 중이라서,\n깜빡해서.\n연락을 못 한 적, 있죠?\n그 연락, ImHere가 대신 보낼게요.',
      ),
      findsOneWidget,
    );
  });
}
