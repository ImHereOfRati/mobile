import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imhere_design_site/main.dart';
import 'package:imhere_design_site/catalog_entry.dart';
import 'package:imhere_design_site/catalog_page.dart';
import 'package:imhere_design_site/catalog_preview.dart';
import 'package:imhere_design_site/device_preview.dart';
import 'package:iamhere/components/components.dart';

void main() {
  testWidgets('문서 사이트에서 컴포넌트 예시를 볼 수 있다', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DesignSite());
    expect(find.text('시작하기'), findsWidgets);
    expect(
      tester.widget<Text>(find.text('ImHere Design')).style?.fontFamily,
      ImHereLogo.fontFamily,
    );

    await tester.tap(find.text('컴포넌트').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('배지').first);
    await tester.pumpAndSettle();
    expect(find.text('전송 완료'), findsOneWidget);
    expect(find.text('전송 실패'), findsOneWidget);
  });

  testWidgets('기준 화면과 작은 화면에서 모든 컴포넌트가 적응한다', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [320.0, 360.0, 430.0, 800.0]) {
      tester.view.physicalSize = Size(width, 780);
      for (final entry in CatalogEntry.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ImHereTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CatalogPreview(entry: entry, onMessage: (_) {}),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '$width: ${entry.title}',
        );
      }
    }
  });

  testWidgets('상단 바와 내비게이션은 모든 미리보기의 폰 화면 위아래에 고정된다', (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final entry in CatalogEntry.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ImHereTheme.light,
          home: Scaffold(body: DevicePreview(entry: entry)),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: entry.title);
      final frame = tester.getRect(
        find.byKey(const Key('galaxy-s26-preview-frame')),
      );
      final nav = tester.getRect(find.byType(ImHereNavigation));
      expect(nav.bottom, closeTo(frame.bottom, 1), reason: entry.title);
      expect(nav.left, greaterThanOrEqualTo(frame.left - 1));
      expect(nav.right, lessThanOrEqualTo(frame.right + 1));
      final bar = tester.getRect(find.byType(ImHereAppHeader));
      expect(bar.top, closeTo(frame.top, 1), reason: entry.title);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ImHereTheme.light,
        home: Scaffold(body: DevicePreview(entry: CatalogEntry.navigation)),
      ),
    );
    await tester.tap(find.text('설정'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('알림'));
    await tester.pump();
    expect(find.text('알림 내역을 열었어요.'), findsOneWidget);
  });

  testWidgets('작은 화면에서 글자를 두 배로 키워도 컴포넌트가 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final entry in CatalogEntry.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ImHereTheme.light,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CatalogPreview(entry: entry, onMessage: (_) {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: entry.title);
    }
  });

  testWidgets('미리 보기는 S26 크기를 기준으로 좁은 화면에 맞춰진다', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final (viewport, expectedWidth) in [(1200.0, 360.0), (320.0, 280.0)]) {
      tester.view.physicalSize = Size(viewport, 1000);
      await tester.pumpWidget(
        MaterialApp(
          theme: ImHereTheme.light,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CatalogContent(entry: CatalogEntry.color),
            ),
          ),
        ),
      );
      await tester.pump();
      final frame = tester.getSize(
        find.byKey(const Key('galaxy-s26-preview-frame')),
      );
      expect(frame.width, closeTo(expectedWidth, 0.01));
      expect(frame.height, closeTo(expectedWidth * 780 / 360, 0.01));
      expect(
        tester.getTopLeft(find.byKey(const Key('galaxy-s26-preview-frame'))).dx,
        closeTo((viewport - expectedWidth) / 2, 0.01),
      );
      expect(tester.takeException(), isNull);
    }
    expect(find.text('#0055B8'), findsOneWidget);
  });

  testWidgets('스위치와 칩을 누르면 바뀐 값이 전달된다', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ImHereTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              ImHereSwitch(
                label: '도착 알림',
                value: true,
                onChanged: (v) => changes.add('switch:$v'),
              ),
              ImHereChip(
                label: '가족',
                selected: false,
                onChanged: (v) => changes.add('chip:$v'),
              ),
              const ImHereSwitch(label: '잠김', value: false, onChanged: null),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('도착 알림'));
    await tester.tap(find.text('가족'));
    await tester.tap(find.text('잠김'));
    await tester.pump();
    expect(changes, ['switch:false', 'chip:true']);
  });

  testWidgets('다이얼로그는 확인하면 true를 돌려준다', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ImHereTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ImHereButton(
              label: '열기',
              onPressed: () async => result = await showImHereDialog(
                context,
                title: '삭제할까요?',
                confirmLabel: '삭제하기',
                destructive: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('삭제할까요?'), findsOneWidget);
    final buttons = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(ImHereButton),
    );
    expect(buttons, findsNWidgets(2));
    expect(
      tester.getSize(buttons.first).width,
      tester.getSize(buttons.last).width,
    );
    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('설명 칸은 항목이 바뀌어도 높이가 같다', (tester) async {
    for (final size in [const Size(1440, 900), const Size(390, 844)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final heights = <double>{};
      for (final entry in CatalogEntry.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ImHereTheme.light,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: CatalogContent(entry: entry),
              ),
            ),
          ),
        );
        await tester.pump();
        heights.add(
          tester.getSize(find.byKey(const Key('catalog-description'))).height,
        );
      }
      expect(heights.length, 1, reason: '$size');
    }
  });

  testWidgets('섹션 전환 컨트롤은 애니메이션 없이 바로 바뀐다', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DesignSite());
    await tester.tap(find.text('컴포넌트').first);
    await tester.pump();
    final segment = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('컴포넌트').first,
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(segment.duration, Duration.zero);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('하단 버튼 두 개도 가로 크기가 같다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ImHereTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ImHereBottomAction(
              label: '장소 저장하기',
              onPressed: () {},
              secondaryLabel: '닫기',
              onSecondaryPressed: () {},
            ),
          ),
        ),
      ),
    );
    final buttons = find.byType(ImHereButton);
    expect(buttons, findsNWidgets(2));
    expect(
      tester.getSize(buttons.first).width,
      tester.getSize(buttons.last).width,
    );
  });

  testWidgets('디자인 시스템 화면은 스크롤 없이 한 화면에 들어간다', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(1440, 900),
      const Size(1280, 720),
      const Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const DesignSite());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$size');
      final frameFinder = find.byKey(const Key('galaxy-s26-preview-frame'));
      final pageScrollables = find
          .descendant(
            of: find.byType(Scaffold).first,
            matching: find.byType(Scrollable),
          )
          .evaluate()
          .where(
            (e) => find
                .ancestor(
                  of: find.byElementPredicate((x) => x == e),
                  matching: frameFinder,
                )
                .evaluate()
                .isEmpty,
          );
      for (final element in pageScrollables) {
        final position =
            ((element as StatefulElement).state as ScrollableState).position;
        expect(position.maxScrollExtent, 0, reason: '$size');
      }
      final frame = tester.getRect(
        find.byKey(const Key('galaxy-s26-preview-frame')),
      );
      expect(frame.bottom, lessThanOrEqualTo(size.height), reason: '$size');
      expect(frame.width / frame.height, closeTo(360 / 780, 0.001));
    }
  });

  testWidgets('로고만 잘난체를 쓰고 나머지 글자는 시스템 글꼴을 쓴다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ImHereTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: const Scaffold(
              body: Column(
                children: [
                  ImHereLogo(),
                  ImHereParagraph(text: '본문'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final logo = tester.widget<Text>(find.text(ImHereLogo.wordmark));
    expect(logo.style?.fontFamily, ImHereLogo.fontFamily);
    // The logo ignores the system text scale.
    // 24 * the 1.2 viewport scale of the 800px test window, not * 2.
    expect(
      tester.getSize(find.text(ImHereLogo.wordmark)).height,
      closeTo(ImHereLogo.fontSize * 1.2, 0.5),
    );
    expect(ImHereTheme.light.textTheme.bodyLarge?.fontFamily, isNull);
    expect(ImHereTheme.dark.textTheme.titleMedium?.fontFamily, isNull);
  });

  testWidgets('상단 바와 하단 영역은 안전 영역을 비켜 간다', (tester) async {
    const insets = EdgeInsets.only(top: 32, bottom: 24);
    await tester.pumpWidget(
      MaterialApp(
        theme: ImHereTheme.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(padding: insets, viewPadding: insets),
            child: Scaffold(
              body: Column(
                children: [
                  const ImHereTopBar(title: '알림 기록'),
                  const Spacer(),
                  ImHereBottomAction(label: '저장하기', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('알림 기록')).dy,
      greaterThanOrEqualTo(insets.top),
    );
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      tester.getBottomLeft(find.text('저장하기')).dy,
      lessThanOrEqualTo(screenHeight - insets.bottom),
    );
  });
}
