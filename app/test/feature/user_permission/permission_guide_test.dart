import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/components/components.dart';
import 'package:iamhere/core/util/korean_text.dart';
import 'package:iamhere/feature/user_permission/model/app_permission.dart';
import 'package:iamhere/feature/user_permission/model/permission_guide_content.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/locate_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_guide_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/feature/user_permission/view/page/permission_guide_page.dart';
import 'package:iamhere/feature/user_permission/viewmodel/permission_guide_view_model.dart';
import 'package:iamhere/theme/imhere_theme.dart';

class _Permission implements PermissionServiceInterface {
  _Permission(this.state);

  PermissionState state;
  int requests = 0;

  @override
  Future<PermissionState> checkPermissionStatus() async => state;

  @override
  Future<PermissionState> requestPermission() async {
    requests++;
    state = PermissionState.grantedAlways;
    return state;
  }

  @override
  Future<bool> isPermissionGranted() async =>
      state == PermissionState.grantedAlways;
}

class _Location extends Fake implements LocatePermissionService {
  _Location(this.state, {this.afterRequest});

  PermissionState state;
  final PermissionState? afterRequest;
  int requests = 0;

  @override
  Future<PermissionState> checkPermissionStatus() async => state;

  @override
  Future<PermissionState> requestAlwaysPermission() async {
    requests++;
    state = afterRequest ?? PermissionState.grantedAlways;
    return state;
  }
}

Future<bool> _accept(
  AppPermission permission, {
  required bool opensSettings,
}) async => true;

Future<bool> _declineLocation(
  AppPermission permission, {
  required bool opensSettings,
}) async => permission != AppPermission.locationAlways;

/// 줄바꿈용 문자를 뺀 화면 글자로 찾는다.
Finder findPlain(String text) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      KoreanText.plain(widget.data ?? widget.textSpan?.toPlainText() ?? '') ==
          text,
  description: 'text "$text"',
);

void main() {
  late _Permission notification;
  late _Permission battery;
  late _Permission contacts;
  late _Location location;
  late int settingsOpened;

  PermissionGuideService build() => PermissionGuideService(
    location: location,
    notification: notification,
    batteryOptimization: battery,
    contacts: contacts,
    isAndroid: true,
    openSettings: () async {
      settingsOpened++;
      return true;
    },
  );

  setUp(() {
    notification = _Permission(PermissionState.denied);
    battery = _Permission(PermissionState.denied);
    contacts = _Permission(PermissionState.denied);
    location = _Location(PermissionState.denied);
    settingsOpened = 0;
  });

  group('view model', () {
    test('requests every missing permission in one pass', () async {
      final service = build();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = permissionGuideViewModelProvider(service);
      final viewModel = container.read(provider.notifier);
      await viewModel.refresh();

      await viewModel.requestAll(confirm: _accept);

      expect(notification.requests, 1);
      expect(location.requests, 1);
      expect(battery.requests, 1);
      expect(contacts.requests, 1);
      expect(viewModel.allGranted, isTrue);
    });

    test('skips permissions that are already granted', () async {
      notification.state = PermissionState.grantedAlways;
      final service = build();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        permissionGuideViewModelProvider(service).notifier,
      );
      await viewModel.refresh();

      await viewModel.requestAll(confirm: _accept);

      expect(notification.requests, 0);
    });

    test('leaves background location alone when the user declines', () async {
      final service = build();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        permissionGuideViewModelProvider(service).notifier,
      );
      await viewModel.refresh();

      await viewModel.requestAll(confirm: _declineLocation);

      expect(location.requests, 0);
      expect(contacts.requests, 1);
      expect(viewModel.allGranted, isFalse);
    });

    test('while-in-use alone does not count as location granted', () async {
      location = _Location(PermissionState.grantedWhenInUse);
      final service = build();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = permissionGuideViewModelProvider(service);
      final viewModel = container.read(provider.notifier);
      await viewModel.refresh();

      expect(
        container.read(provider).isGranted(AppPermission.locationAlways),
        isFalse,
      );
    });

    test('opens settings when a retried request does not upgrade', () async {
      location = _Location(
        PermissionState.grantedWhenInUse,
        afterRequest: PermissionState.grantedWhenInUse,
      );
      final service = build();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final viewModel = container.read(
        permissionGuideViewModelProvider(service).notifier,
      );
      await viewModel.refresh();

      await viewModel.request(AppPermission.locationAlways, confirm: _accept);
      expect(location.requests, 1);
      expect(settingsOpened, 0);

      await viewModel.request(AppPermission.locationAlways, confirm: _accept);
      expect(location.requests, 1);
      expect(settingsOpened, 1);
    });

    test('reports whether every permission is already granted', () async {
      final service = build();
      expect(await service.areAllGranted(), isFalse);

      notification.state = PermissionState.grantedAlways;
      battery.state = PermissionState.grantedAlways;
      contacts.state = PermissionState.grantedAlways;
      location.state = PermissionState.grantedWhenInUse;
      // 위치는 '앱 사용 중에만 허용'으로는 부족하다.
      expect(await service.areAllGranted(), isFalse);

      location.state = PermissionState.grantedAlways;
      expect(await service.areAllGranted(), isTrue);
    });

    test('ignores notification when push is unavailable', () async {
      final service = PermissionGuideService(
        location: location,
        notification: notification,
        batteryOptimization: battery,
        contacts: contacts,
        isAndroid: true,
        notificationAvailable: false,
      );

      expect(service.permissions, isNot(contains(AppPermission.notification)));
    });

    test('hides battery optimization outside Android', () {
      final service = PermissionGuideService(
        location: location,
        notification: notification,
        batteryOptimization: battery,
        contacts: contacts,
        isAndroid: false,
      );

      expect(
        service.permissions,
        isNot(contains(AppPermission.batteryOptimization)),
      );
    });
  });

  group('page', () {
    Future<void> pump(
      WidgetTester tester, {
      required VoidCallback onDone,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ImHereAppTheme.light,
            home: PermissionGuidePage(service: build(), onDone: onDone),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('grants everything after confirming each guided step', (
      tester,
    ) async {
      var done = false;
      await pump(tester, onDone: () => done = true);
      expect(find.text('허용 필요'), findsNWidgets(4));

      await tester.tap(find.widgetWithText(ImHereButton, '모두 허용하기'));
      // 안내 시트의 깜빡임과 요청 스피너가 계속 돌아 pumpAndSettle은 쓰지 않는다.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 설정 화면으로 이동하기 전에 무엇을 눌러야 하는지 먼저 보여 준다.
      expect(findPlain('위치를 항상 허용해 주세요'), findsOneWidget);
      expect(findPlain('설정으로 이동 버튼을 눌러요.'), findsOneWidget);
      expect(findPlain('위치 권한 화면에서 항상 허용을 눌러요.'), findsOneWidget);
      expect(find.text('여기를 눌러요'), findsOneWidget);
      expect(location.requests, 0);

      await tester.tap(find.widgetWithText(ImHereButton, '설정으로 이동'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(location.requests, 1);

      expect(findPlain('배터리 최적화에서 제외해 주세요'), findsOneWidget);
      await tester.tap(find.widgetWithText(ImHereButton, '계속'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('허용됨'), findsNWidgets(4));
      expect(find.widgetWithText(ImHereButton, '시작하기'), findsOneWidget);

      await tester.tap(find.widgetWithText(ImHereButton, '시작하기'));
      expect(done, isTrue);
    });

    testWidgets('does not leave the app when the guide is dismissed', (
      tester,
    ) async {
      await pump(tester, onDone: () {});

      await tester.tap(find.widgetWithText(ImHereButton, '모두 허용하기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.widgetWithText(ImHereButton, '나중에 할게요').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(location.requests, 0);
    });

    testWidgets('can be skipped for now', (tester) async {
      var done = false;
      await pump(tester, onDone: () => done = true);

      await tester.tap(find.widgetWithText(ImHereButton, '나중에 할게요'));

      expect(done, isTrue);
      expect(notification.requests, 0);
    });

    testWidgets('explains the extra step when only while-in-use is allowed', (
      tester,
    ) async {
      location = _Location(PermissionState.grantedWhenInUse);
      await pump(tester, onDone: () {});

      expect(findPlain('설정 화면에서 "항상 허용"을 선택해 주세요.'), findsOneWidget);
    });
  });

  group('guide content', () {
    test('tells exactly where to tap when location opens settings', () {
      final content = PermissionGuideContent.of(
        AppPermission.locationAlways,
        opensSettings: true,
        isAndroid: true,
      )!;

      expect(content.steps.map((step) => step.text), [
        '설정으로 이동 버튼을 눌러요.',
        '권한을 누른 뒤 위치 항목을 눌러요.',
        '항상 허용을 선택해요.',
        '뒤로 가기로 ImHere에 돌아와요.',
      ]);
      expect(content.steps[1].highlights, ['권한', '위치']);
      expect(
        content.options.where((option) => option.target).single.label,
        '항상 허용',
      );
      expect(content.purpose, isNotNull);
    });

    test('the first step names the button the sheet actually shows', () {
      for (final permission in [
        AppPermission.locationAlways,
        AppPermission.batteryOptimization,
      ]) {
        for (final opensSettings in [false, true]) {
          final content = PermissionGuideContent.of(
            permission,
            opensSettings: opensSettings,
            isAndroid: true,
          )!;

          expect(content.steps.first.text, contains(content.confirmLabel));
        }
      }
    });

    test('keeps each step to a single action', () {
      final content = PermissionGuideContent.of(
        AppPermission.locationAlways,
        opensSettings: true,
        isAndroid: true,
      )!;

      for (final step in content.steps) {
        expect('.'.allMatches(step.text).length, 1, reason: step.text);
      }
    });

    test('explains the dialog before asking for battery optimization', () {
      final content = PermissionGuideContent.of(
        AppPermission.batteryOptimization,
        opensSettings: false,
        isAndroid: true,
      )!;

      expect(content.steps[1].text, '나오는 창에서 허용을 눌러요.');
    });

    test('needs no guide for a first notification or contacts request', () {
      for (final permission in [
        AppPermission.notification,
        AppPermission.contacts,
      ]) {
        expect(
          PermissionGuideContent.of(
            permission,
            opensSettings: false,
            isAndroid: true,
          ),
          isNull,
        );
      }
    });

    test('uses the system dialog wording on iOS', () {
      final content = PermissionGuideContent.of(
        AppPermission.locationAlways,
        opensSettings: false,
        isAndroid: false,
      )!;

      expect(content.steps[1].text, '나오는 창에서 항상 허용으로 변경을 눌러요.');
    });
  });

  group('Korean text', () {
    test('keeps words together without changing what is shown', () {
      final joined = KoreanText.keepWords('항상 허용을 눌러요.\n다음 줄');

      expect(KoreanText.plain(joined), '항상 허용을 눌러요.\n다음 줄');
      expect(joined, isNot('항상 허용을 눌러요.\n다음 줄'));
      expect(joined.contains(' '), isTrue);
      expect(joined.contains('\n'), isTrue);
    });
  });
}
