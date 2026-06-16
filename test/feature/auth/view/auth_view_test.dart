import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/base/result/result.dart';
import 'package:iamhere/common/base/result/result_message.dart';
import 'package:iamhere/feature/auth/service/login_result.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/feature/auth/view/auth_view.dart';
import 'package:iamhere/feature/auth/view_model/auth_view_model.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_view_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AuthViewModel>(), MockSpec<TokenStorageService>()])
void main() {
  late MockAuthViewModel mockAuthViewModel;
  late MockTokenStorageService mockTokenStorageService;

  provideDummy<Result<MemberState>>(Success(MemberState.existingUser));
  provideDummy<Result<ResultMessage>>(Success(ResultMessage.kakaoAuthSuccess));

  setUp(() async {
    mockAuthViewModel = MockAuthViewModel();
    mockTokenStorageService = MockTokenStorageService();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<TokenStorageService>(
      mockTokenStorageService,
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    // 로그인 성공 시 context.go 로 이동하므로 GoRouter 가 필요하다.
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => AuthView(mockAuthViewModel)),
        GoRoute(
          path: '/geofence',
          builder: (_, __) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/terms-consent',
          builder: (_, __) => const Scaffold(body: SizedBox()),
        ),
      ],
    );

    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(402, 874),
        builder: (context, child) {
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  group('AuthView Widget Tests', () {
    testWidgets('시작하기 버튼이 정상적으로 렌더링 되어야 한다', (
      WidgetTester tester,
    ) async {
      // given & when
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(createWidgetUnderTest());

      // then
      expect(find.text('시작하기'), findsOneWidget);
    });

    testWidgets('reason=inactive 쿼리 파라미터가 있으면 비활성화 안내 문구가 표시된다', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/?reason=inactive',
        routes: [
          GoRoute(path: '/', builder: (_, __) => AuthView(mockAuthViewModel)),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(402, 874),
            builder: (context, child) {
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          '현재 계정이 비활성 상태입니다. 운영자에게 문의하거나 다시 로그인해 주세요.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('reason 파라미터 없을 때 비활성화 안내 문구가 표시되지 않는다', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.text(
          '현재 계정이 비활성 상태입니다. 운영자에게 문의하거나 다시 로그인해 주세요.',
        ),
        findsNothing,
      );
    });

    testWidgets('시작하기 후 Kakao 선택 시 handleKakaoLogin이 호출되어야 한다', (
      WidgetTester tester,
    ) async {
      // given (시나리오 설정)
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 기존 사용자 로그인 응답
      when(
        mockAuthViewModel.handleKakaoLogin(),
      ).thenAnswer((_) async => Success(MemberState.existingUser));

      when(
        mockAuthViewModel.requestFCMTokenAndSendToServer(),
      ).thenAnswer((_) async => Success(ResultMessage.fcmTokenServerSuccess));

      // FCM 토큰 전송 (기존 사용자에게만)
      when(
        mockAuthViewModel.requestFCMTokenAndSendToServer(),
      ).thenAnswer((_) async => Success(ResultMessage.fcmTokenServerSuccess));

      // 토큰 저장소
      when(
        mockTokenStorageService.getAccessToken(),
      ).thenAnswer((_) async => 'mock_access_token');
      when(
        mockTokenStorageService.getPendingAuth(),
      ).thenAnswer((_) async => false);

      // when (화면 빌드 및 버튼 탭)
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kakao로 계속하기'));

      // 비동기 로직들이 실행될 시간을 줌
      await tester.pumpAndSettle();

      // then
      // handleKakaoLogin이 호출되었는지 확인
      verify(mockAuthViewModel.handleKakaoLogin()).called(1);
    });

    testWidgets('시작하기 후 Google 선택 시 handleGoogleLogin이 호출되어야 한다', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        mockAuthViewModel.handleGoogleLogin(),
      ).thenAnswer((_) async => Success(MemberState.existingUser));
      when(
        mockAuthViewModel.requestFCMTokenAndSendToServer(),
      ).thenAnswer((_) async => Success(ResultMessage.fcmTokenServerSuccess));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Google로 계속하기'));
      await tester.pumpAndSettle();

      verify(mockAuthViewModel.handleGoogleLogin()).called(1);
    });
  });
}
