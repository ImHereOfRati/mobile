import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iamhere/components/components.dart';
import 'package:imhere_landing_page/legal_document_page.dart';
import 'package:imhere_landing_page/main.dart';

Future<LegalTermDocument> _fakeTermFetcher(LegalDocumentType type) async {
  return switch (type) {
    LegalDocumentType.privacy => const LegalTermDocument(
      type: 'PRIVACY',
      title: 'ImHere 개인정보처리방침',
      content:
          '1. 수집하는 개인정보 항목\n위치 기반 알림 제공을 위해 필요한 최소 정보를 처리합니다.\n2. 보유 및 이용 기간\n회원 탈퇴 시 지체 없이 파기합니다.',
      effectiveDate: '2026-09-01',
      version: 2,
    ),
    LegalDocumentType.terms => const LegalTermDocument(
      type: 'SERVICE',
      title: 'ImHere 서비스 이용약관',
      content: '1. 목적\n본 약관은 ImHere 위치 기반 알림 서비스의 이용 조건을 규정합니다.',
      effectiveDate: '2026-09-01',
      version: 1,
    ),
  };
}

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const ImHereLandingApp(termFetcher: _fakeTermFetcher),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('스크롤하면 장면이 고정된 채 단계별로 전환된다', (tester) async {
    await pumpAt(tester, const Size(1440, 900));

    expect(find.text('출발할 때, 도착할 때,\n연락은 ImHere가 대신 보낼게요'), findsOneWidget);
    expect(find.text('가는 곳만\n골라두세요'), findsNothing);

    final scroll = find.byKey(const Key('landing-scroll-view'));
    Future<void> scrollTo(double offset) async {
      final controller = tester.widget<CustomScrollView>(scroll).controller!;
      controller.jumpTo(offset);
      await tester.pumpAndSettle();
    }

    // 장면 2(선언문)를 지나 장면 3 진입 후 단계별 문구가 바뀐다.
    final base = 832.0 * (0.9 + 1.6) + 832.0 * 2;
    await scrollTo(base + 100);
    expect(find.text('가는 곳만\n골라두세요'), findsOneWidget);
    await scrollTo(base + 832.0 * 0.9 + 100);
    expect(find.text('앱이 없는 분께는\n문자로 보내요'), findsOneWidget);
    await scrollTo(base + 832.0 * 1.8 + 100);
    expect(find.text('앱을 꺼둬도\n알아서 보내요'), findsOneWidget);
    await scrollTo(base + 832.0 * 2.7 + 100);
    expect(find.text('누구에게 갔는지\n한눈에 확인해요'), findsOneWidget);
  });

  testWidgets('폰 목업 안 디자인시스템 컴포넌트가 인터랙션된다', (tester) async {
    await pumpAt(tester, const Size(1440, 900));
    final controller = tester
        .widget<CustomScrollView>(find.byKey(const Key('landing-scroll-view')))
        .controller!;
    controller.jumpTo(832.0 * 2.5 + 832.0 * 2 + 100);
    await tester.pumpAndSettle();

    final homeToggle = find.byKey(const ValueKey('phone-place-toggle-우리 집'));
    expect(tester.widget<ImHereSwitch>(homeToggle).value, isTrue);
    await tester.tap(homeToggle);
    await tester.pumpAndSettle();
    expect(tester.widget<ImHereSwitch>(homeToggle).value, isFalse);
  });

  testWidgets('앱 다운로드 버튼을 누르면 Google Play 다운로드 및 iOS 안내 모달이 열린다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var launched = false;
    await tester.pumpWidget(
      ImHereLandingApp(
        termFetcher: _fakeTermFetcher,
        onLaunchPlayStore: () async {
          launched = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header-download-button')));
    await tester.pumpAndSettle();

    expect(find.text('ImHere 앱 다운로드'), findsOneWidget);
    expect(find.text('iOS 앱 · 현재 제공 계획 없음'), findsOneWidget);

    await tester.tap(find.byKey(const Key('google-play-download-button')));
    await tester.pumpAndSettle();
    expect(launched, isTrue);
  });

  testWidgets('헤더와 초기 쿼리를 통해 개인정보처리방침 및 서비스 약관을 조회할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ImHereLandingApp(termFetcher: _fakeTermFetcher),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header-privacy-button')));
    await tester.pumpAndSettle();
    expect(find.text('ImHere 개인정보처리방침'), findsOneWidget);
    expect(find.text('1. 수집하는 개인정보 항목'), findsOneWidget);

    await tester.tap(find.byKey(const Key('header-terms-button')));
    await tester.pumpAndSettle();
    expect(find.text('ImHere 서비스 이용약관'), findsOneWidget);

    await tester.tap(find.byKey(const Key('legal-back-home-button')));
    await tester.pumpAndSettle();
    expect(find.text('출발할 때, 도착할 때,\n연락은 ImHere가 대신 보낼게요'), findsOneWidget);
  });

  testWidgets('데스크톱과 모바일 뷰포트에서 오버플로 없이 반응형으로 동작한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(1440, 900),
      const Size(960, 800),
      const Size(390, 844),
      const Size(320, 720),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        const ImHereLandingApp(termFetcher: _fakeTermFetcher),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<CustomScrollView>(
            find.byKey(const Key('landing-scroll-view')),
          )
          .controller!;
      final max = controller.position.maxScrollExtent;
      for (var offset = 0.0; offset <= max; offset += max / 40) {
        controller.jumpTo(offset);
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Viewport $size at $offset',
        );
      }
    }
  });
}
