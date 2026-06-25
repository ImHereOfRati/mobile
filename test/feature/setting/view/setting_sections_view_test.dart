import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/feature/setting/view/setting_sections_view.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model_state.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

class _FakeDio extends Fake implements Dio {
  _FakeDio(this.deleteResponse);

  final Response<dynamic> deleteResponse;

  int deleteCallCount = 0;
  String? deletedPath;
  Options? deletedOptions;

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    deleteCallCount++;
    deletedPath = path;
    deletedOptions = options;
    return deleteResponse as Response<T>;
  }
}

class _FakeTokenStorageService extends Fake implements TokenStorageService {
  int deleteAllTokensCallCount = 0;

  @override
  Future<void> deleteAllTokens() async {
    deleteAllTokensCallCount++;
  }
}

void main() {
  late _FakeDio fakeDio;
  late _FakeTokenStorageService fakeTokenStorageService;

  final state = SettingViewModelState(
    appVersion: 'v1.2.3',
  );

  setUp(() async {
    fakeDio = _FakeDio(
      Response(
        requestOptions: RequestOptions(path: '/api/users/my/withdrawal'),
        statusCode: 200,
        data: const {
          'imhereResponseCode': 'SUCCESS',
          'message': 'OK',
        },
      ),
    );
    fakeTokenStorageService = _FakeTokenStorageService();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<Dio>(fakeDio);
    GetIt.instance.registerSingleton<TokenStorageService>(
      fakeTokenStorageService,
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget buildWidget() {
    final router = GoRouter(
      initialLocation: AppRoutes.setting,
      routes: [
        GoRoute(
          path: AppRoutes.setting,
          builder: (_, __) => Scaffold(
            body: SettingSectionsView(state: state),
          ),
        ),
        GoRoute(
          path: AppRoutes.auth,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('auth-screen')),
          ),
        ),
      ],
    );

    return ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(402, 874),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  testWidgets('설정 화면 하단에 회원 탈퇴 버튼이 표시된다', (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final withdrawButton = find.text('회원 탈퇴');
    await tester.scrollUntilVisible(
      withdrawButton,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(withdrawButton, findsOneWidget);
  });

  testWidgets('회원 탈퇴를 확인하면 API 호출 후 auth 화면으로 이동한다', (
    tester,
  ) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final withdrawButton = find.text('회원 탈퇴');
    await tester.scrollUntilVisible(
      withdrawButton,
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    await tester.tap(withdrawButton);
    await tester.pumpAndSettle();

    expect(find.text('회원 탈퇴'), findsWidgets);
    expect(
      find.text('탈퇴하면 계정과 연결된 정보가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'),
      findsOneWidget,
    );

    await tester.tap(find.text('탈퇴'));
    await tester.pumpAndSettle();

    expect(fakeDio.deleteCallCount, 1);
    expect(fakeDio.deletedPath, '/api/users/my/withdrawal');
    expect(
      fakeDio.deletedOptions?.extra?['requiresAuthentication'],
      true,
    );
    expect(fakeTokenStorageService.deleteAllTokensCallCount, 1);
    expect(find.text('auth-screen'), findsOneWidget);
  });
}
