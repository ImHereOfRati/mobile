import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/setting/model/setting_status.dart';
import 'package:iamhere/feature/setting/model/user_me_response_dto.dart';
import 'package:iamhere/feature/setting/service/setting_status_service_interface.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/feature/setting/view/page/setting_page.dart';
import 'package:iamhere/feature/terms/viewmodel/terms_acceptance_view_model.dart';
import 'package:iamhere/integration/firebase/analytics_reporter.dart';
import 'package:iamhere/theme/imhere_theme.dart';

UserMeResponseDto _user(String nickname) => UserMeResponseDto(
  id: 'user-1',
  email: 'test@example.com',
  nickname: nickname,
  oAuth2Provider: 'KAKAO',
);

class _FakeUserMeService implements UserMeServiceInterface {
  var withdrawCalls = 0;
  final changedNicknames = <String>[];

  @override
  Future<UserMeResponseDto?> fetchMyInfo() async => _user('기존');

  @override
  Future<UserMeResponseDto> changeNickname(String nickname) async {
    changedNicknames.add(nickname);
    return _user(nickname);
  }

  @override
  Future<void> withdraw() async => withdrawCalls++;
}

class _FakeTokenStorage implements TokenStorageService {
  var deleteCalls = 0;

  @override
  Future<void> deleteAllTokens() async => deleteCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStatusService implements SettingStatusServiceInterface {
  @override
  Future<SettingStatus> load() async => SettingStatus(
    permissions: const {
      SettingPermission.notification: true,
      SettingPermission.locationAlways: false,
      SettingPermission.batteryOptimization: false,
      SettingPermission.contacts: true,
    },
    lastDelivery: LastDelivery(
      geofenceName: '집',
      occurredAt: DateTime(2026, 10, 25, 15, 7),
    ),
    appVersion: '1.2.3 (45)',
  );

  @override
  Future<void> requestPermission(SettingPermission permission) async {}

  @override
  Future<void> openAppSettings() async {}
}

class _NoopAnalytics implements AnalyticsReporter {
  @override
  Future<void> setConsent(bool granted) async {}

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}
}

void main() {
  late _FakeUserMeService userMe;
  late _FakeTokenStorage tokens;
  late ValueNotifier<ThemeMode> themeMode;
  late List<ThemeMode> savedThemes;
  late List<String> opened;
  var sendHistoryTaps = 0;
  var agreementsTaps = 0;

  setUp(() {
    userMe = _FakeUserMeService();
    tokens = _FakeTokenStorage();
    themeMode = ValueNotifier(ThemeMode.light);
    savedThemes = [];
    opened = [];
    sendHistoryTaps = 0;
    agreementsTaps = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authAnalyticsReporterProvider.overrideWithValue(_NoopAnalytics()),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeMode,
          builder: (context, mode, _) => MaterialApp(
            theme: ImHereAppTheme.light,
            darkTheme: ImHereAppTheme.dark,
            themeMode: mode,
            home: SettingPage(
              userMeService: userMe,
              tokenStorage: tokens,
              statusService: _FakeStatusService(),
              themeMode: themeMode,
              saveTheme: (mode) async => savedThemes.add(mode),
              onOpenSendHistory: () => sendHistoryTaps++,
              onOpenAgreements: () => agreementsTaps++,
              openUrl: (uri) async {
                opened.add(uri.toString());
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows account, permissions, last delivery and version', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('기존'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('허용됨'), findsNWidgets(2));
    expect(find.text('허용 안 됨'), findsNWidgets(2));
    expect(find.text('집 · 2026.10.25 15:07'), findsOneWidget);
    expect(find.text('1.2.3 (45)'), findsOneWidget);
  });

  testWidgets('navigates to send history and agreements', (tester) async {
    await pump(tester);

    await tester.tap(find.text('마지막 자동 전송'));
    await tester.tap(find.text('약관 동의 관리'));

    expect(sendHistoryTaps, 1);
    expect(agreementsTaps, 1);
  });

  testWidgets('opens the support page externally', (tester) async {
    await pump(tester);

    await tester.tap(find.text('문의하기'));

    expect(opened, [settingSupportUrl]);
  });

  testWidgets('toggling dark mode updates and saves the theme', (tester) async {
    await pump(tester);

    await tester.tap(find.text('다크 모드'));
    await tester.pumpAndSettle();

    expect(themeMode.value, ThemeMode.dark);
    expect(savedThemes, [ThemeMode.dark]);
  });

  testWidgets('edits the nickname from the sheet', (tester) async {
    await pump(tester);

    await tester.tap(find.text('닉네임 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '새 닉네임');
    await tester.tap(find.widgetWithText(ImHereButton, '저장'));
    await tester.pumpAndSettle();

    expect(userMe.changedNicknames, ['새 닉네임']);
    expect(find.text('새 닉네임'), findsOneWidget);
  });

  testWidgets('cancelling the nickname sheet closes it without saving', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('닉네임 수정'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ImHereButton, '취소'), findsOneWidget);
    expect(find.widgetWithText(ImHereButton, '저장'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '새 닉네임');
    await tester.tap(find.widgetWithText(ImHereButton, '취소'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(userMe.changedNicknames, isEmpty);
    expect(find.text('기존'), findsOneWidget);
  });

  testWidgets('sign out asks for confirmation before clearing the session', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(ImHereButton, '로그아웃'));
    await tester.pumpAndSettle();
    expect(tokens.deleteCalls, 0);

    await tester.tap(find.widgetWithText(ImHereButton, '로그아웃').last);
    await tester.pumpAndSettle();

    expect(tokens.deleteCalls, 1);
  });

  testWidgets('withdrawal deletes the account only after confirmation', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.widgetWithText(ImHereButton, '회원 탈퇴'));
    await tester.pumpAndSettle();
    expect(userMe.withdrawCalls, 0);

    await tester.tap(find.widgetWithText(ImHereButton, '회원 탈퇴').last);
    await tester.pumpAndSettle();

    expect(userMe.withdrawCalls, 1);
    expect(tokens.deleteCalls, 1);
  });
}
