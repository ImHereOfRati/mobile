import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/feature/terms/service/dto/terms_list_request_dto.dart';
import 'package:iamhere/feature/terms/service/dto/terms_type.dart';
import 'package:iamhere/feature/terms/view/terms_list_view.dart';
import 'package:iamhere/feature/terms/view_model/terms_list_view_model.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

class _FakeTermsListViewModel extends TermsListViewModel {
  _FakeTermsListViewModel(this._terms);

  final List<TermsListRequestDto> _terms;

  @override
  Future<List<TermsListRequestDto>> build() async => _terms;
}

class _InMemoryTokenStorage implements TokenStorageService {
  String? accessToken = 'access_token';
  String? refreshToken = 'refresh_token';
  bool pendingAuth = true;
  String? userStatus = 'PENDING';
  bool? isActive = false;

  @override
  Future<void> deleteAccessToken() async {
    accessToken = null;
  }

  @override
  Future<void> deleteAllTokens() async {
    accessToken = null;
    refreshToken = null;
    pendingAuth = false;
    userStatus = null;
    isActive = null;
  }

  @override
  Future<void> deleteRefreshToken() async {
    refreshToken = null;
  }

  @override
  Future<bool> getPendingAuth() async => pendingAuth;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<bool?> getIsActive() async => isActive;

  @override
  Future<String?> getUserStatus() async => userStatus;

  @override
  Future<void> saveAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<void> saveAuthSnapshot({String? userStatus, bool? isActive}) async {
    pendingAuth = userStatus == 'PENDING';
    this.userStatus = userStatus;
    this.isActive = isActive;
  }

  @override
  Future<void> saveIsActive(bool? isActive) async {
    this.isActive = isActive;
  }

  @override
  Future<void> savePendingAuth(bool isPending) async {
    pendingAuth = isPending;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    refreshToken = token;
  }

  @override
  Future<void> saveUserStatus(String? userStatus) async {
    this.userStatus = userStatus;
  }
}

void main() {
  late _InMemoryTokenStorage tokenStorage;

  setUp(() async {
    tokenStorage = _InMemoryTokenStorage();

    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<TokenStorageService>(tokenStorage);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('빈 약관 목록이면 activation 호출 없이 바로 다음 화면으로 이동한다', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.termsConsent,
      routes: [
        GoRoute(
          path: AppRoutes.termsConsent,
          builder: (_, __) => const TermsListView(),
        ),
        GoRoute(
          path: AppRoutes.geofence,
          builder: (_, __) => const Scaffold(body: Text('Geofence Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          termsListViewModelProvider.overrideWith(
            () => _FakeTermsListViewModel(const []),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(402, 874),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Geofence Home'), findsOneWidget);
    expect(tokenStorage.userStatus, 'ACTIVE');
    expect(tokenStorage.isActive, true);
    expect(tokenStorage.pendingAuth, false);
  });

  testWidgets('약관이 있으면 목록 화면을 렌더링한다', (WidgetTester tester) async {
    final terms = [
      TermsListRequestDto(
        id: 1,
        version: 1,
        type: TermsType.service,
        title: '서비스 이용약관',
        content: '본문',
        effectiveDate: DateTime(2026, 1, 1),
        isRequired: true,
      ),
    ];

    final router = GoRouter(
      initialLocation: AppRoutes.termsConsent,
      routes: [
        GoRoute(
          path: AppRoutes.termsConsent,
          builder: (_, __) => const TermsListView(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          termsListViewModelProvider.overrideWith(
            () => _FakeTermsListViewModel(terms),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(402, 874),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('동의하고 시작하기'), findsOneWidget);
  });
}
