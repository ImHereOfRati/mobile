import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/model/service/account/auth_account_sync_service.dart';
import 'package:iamhere/feature/auth/view/page/auth_page.dart';
import 'package:iamhere/feature/auth/viewmodel/auth_invalidation_notifier.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/setting/service/setting_status_service_interface.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:iamhere/feature/setting/view/page/setting_page.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/setting/view/page/agreements_page.dart';
import 'package:iamhere/feature/setting/view/page/term_detail_page.dart';
import 'package:iamhere/feature/terms/view/page/terms_page.dart';
import 'package:iamhere/feature/geofence/delivery/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_scheduler.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/model/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/user_permission/service/locate_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_guide_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_interface.dart';
import 'package:iamhere/feature/user_permission/view/page/permission_guide_page.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/integration/fcm/fcm_message_handler.dart';
import 'package:iamhere/shell/bridge/bridge_rpc_server.dart';
import 'package:iamhere/shell/theme_preference_service.dart';
import 'package:iamhere/shell/view/native_app_shell.dart';
import 'package:iamhere/theme/imhere_theme.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';
import 'package:iamhere/shell/web_url_resolver.dart';
import 'package:iamhere/shell/webview_host.dart';

/// 로그인 상태가 허용하는 화면 범위.
enum _Access { signedOut, pendingTerms, active }

class ShellApp extends StatefulWidget {
  final WebUrlResolver webUrlResolver;
  final BridgeRpcServer rpcServer;
  final ValueNotifier<ThemeMode> themeMode;
  final Future<void> Function(ThemeMode)? saveTheme;
  final ConnectivityProbe isOnline;
  final bool enablePush;
  final bool forceUpdate;
  final VoidCallback? onUpdate;

  const ShellApp({
    super.key,
    required this.webUrlResolver,
    required this.rpcServer,
    required this.themeMode,
    required this.isOnline,
    this.saveTheme,
    this.enablePush = true,
    this.forceUpdate = false,
    this.onUpdate,
  });

  @override
  State<ShellApp> createState() => _ShellAppState();
}

class _ShellAppState extends State<ShellApp> {
  static const _deliveryQueuePollInterval = Duration(seconds: 30);
  static const _webPath = '/web';
  static const _settingPath = '/setting';

  // Riverpod family 인자로 쓰이므로 화면이 다시 그려져도 같은 인스턴스여야
  // 한다. getIt이 factory로 등록한 서비스는 한 번만 꺼내 둔다.
  final _tokenStorage = getIt<TokenStorageService>();
  final _authService = getIt<AuthService>();
  final _termsService = getIt<TermsService>();
  late final _permissionGuideService = PermissionGuideService(
    location: LocatePermissionService(),
    notification: getIt<PermissionServiceInterface>(instanceName: 'fcmAlert'),
    batteryOptimization: getIt<PermissionServiceInterface>(
      instanceName: 'batteryOptimization',
    ),
    contacts: getIt<PermissionServiceInterface>(instanceName: 'friend'),
  );
  final _loginCoordinator = getIt<SocialLoginService>();
  final _userMeService = getIt<UserMeServiceInterface>();
  final _statusService = getIt<SettingStatusServiceInterface>();

  final StreamController<String> _webPaths =
      StreamController<String>.broadcast();
  late Future<Uri> _webUrl;
  late final GoRouter _router;
  late final AppLifecycleListener _lifecycleListener;
  Timer? _deliveryRetryTimer;
  late final ProviderSubscription<int> _authInvalidationSubscription;

  @override
  void initState() {
    super.initState();
    _webUrl = widget.webUrlResolver.resolve();
    _router = _createRouter();
    _authInvalidationSubscription = getIt<ProviderContainer>().listen(
      authInvalidationProvider,
      (previous, next) {
        if (previous != next) _router.refresh();
      },
    );
    if (widget.enablePush) {
      setupShellMessageTapHandler(_handlePushPath);
    }
    _startDeliveryRetryTimer();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _startDeliveryRetryTimer();
        unawaited(_drainDeliveryQueue());
        unawaited(_syncAuthAccount());
        unawaited(_syncNativeGeofences());
      },
      onPause: _stopDeliveryRetryTimer,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncNativeGeofences());
      unawaited(_syncAuthAccount());
    });
  }

  @override
  void dispose() {
    widget.themeMode.dispose();
    _stopDeliveryRetryTimer();
    _authInvalidationSubscription.close();
    _lifecycleListener.dispose();
    _router.dispose();
    unawaited(_webPaths.close());
    super.dispose();
  }

  void _startDeliveryRetryTimer() {
    _deliveryRetryTimer ??= Timer.periodic(_deliveryQueuePollInterval, (_) {
      unawaited(_drainDeliveryQueue());
    });
  }

  void _stopDeliveryRetryTimer() {
    _deliveryRetryTimer?.cancel();
    _deliveryRetryTimer = null;
  }

  Future<void> _drainDeliveryQueue() async {
    if (!getIt.isRegistered<GeofenceDeliveryPipeline>()) return;
    try {
      await getIt<GeofenceDeliveryPipeline>().processPending();
      if (getIt.isRegistered<GeofenceRetryScheduler>()) {
        await getIt<GeofenceRetryScheduler>().scheduleNextIfNeeded();
      }
    } catch (error, stack) {
      AppLogger.error('Background delivery retry failed', error, stack);
    }
  }

  Future<void> _syncAuthAccount() async {
    if (!getIt.isRegistered<AuthAccountSyncService>()) return;
    try {
      await getIt<AuthAccountSyncService>().syncIfSignedIn();
    } catch (error, stack) {
      AppLogger.error('Auth account sync failed', error, stack);
    }
  }

  Future<void> _syncNativeGeofences() async {
    try {
      final registrar = getIt<NativeGeofenceRegistrarInterface>();
      await registrar.initialize();
      final all = await getIt<GeofenceLocalRepository>().findAll();
      await registrar.syncAll(all.where((item) => item.isActive).toList());
      await _drainDeliveryQueue();
    } on MissingBackgroundLocationException catch (error) {
      AppLogger.warning('Native geofence sync deferred: ${error.state.name}');
    } catch (error, stack) {
      AppLogger.error('Native geofence sync failed', error, stack);
    }
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      redirect: _redirect,
      routes: [
        GoRoute(path: '/', builder: (_, __) => const ShellStatusView.splash()),
        GoRoute(
          path: '/error',
          builder: (_, __) =>
              ShellStatusView.fatalError(onRetry: () => _router.go('/')),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, __) => AuthPage(
            authLoginCoordinator: _loginCoordinator,
            onAuthenticated: _handleAuthenticated,
            requestLocationPermission: () async {
              await getIt<PermissionServiceInterface>(
                instanceName: 'location',
              ).requestPermission();
            },
            requestNotificationPermission: widget.enablePush
                ? () async {
                    await getIt<PermissionServiceInterface>(
                      instanceName: 'fcmAlert',
                    ).requestPermission();
                  }
                : null,
          ),
        ),
        GoRoute(
          path: '/terms',
          builder: (_, __) => TermsPage(
            authService: _authService,
            termsService: _termsService,
            onDone: _handleTermsAccepted,
          ),
        ),
        GoRoute(
          path: '/permissions',
          builder: (_, __) => PermissionGuidePage(
            service: _permissionGuideService,
            onDone: () => _router.go(_webPath),
          ),
        ),
        ShellRoute(
          builder: _buildShell,
          routes: [
            // 웹이 그리는 모든 화면. 실제 경로는 웹 라우터가 따로 관리한다.
            GoRoute(
              path: _webPath,
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: SizedBox.shrink()),
            ),
            GoRoute(
              path: _settingPath,
              pageBuilder: (_, __) => NoTransitionPage(child: _settingPage()),
              routes: [
                GoRoute(
                  path: 'permissions',
                  builder: (_, __) => PermissionGuidePage(
                    service: _permissionGuideService,
                    showHeader: false,
                    onDone: _backFromNative,
                  ),
                ),
                GoRoute(
                  path: 'agreements',
                  builder: (_, __) =>
                      AgreementsPage(termsService: _termsService),
                  routes: [
                    GoRoute(
                      path: ':termId',
                      builder: (_, state) => TermDetailPage(
                        termsService: _termsService,
                        termId:
                            int.tryParse(state.pathParameters['termId']!) ?? -1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _settingPage() => SettingPage(
    userMeService: _userMeService,
    tokenStorage: _tokenStorage,
    statusService: _statusService,
    themeMode: widget.themeMode,
    saveTheme: widget.saveTheme ?? ThemePreferenceService().save,
    onOpenSendHistory: () => _openWeb('/record/send-history'),
    onOpenAgreements: () => _router.push('/setting/agreements'),
    onOpenPermissionGuide: () => _router.push('/setting/permissions'),
  );

  Widget _buildShell(BuildContext context, GoRouterState state, Widget child) {
    final path = state.uri.path;
    final native = NativeShellPage.isNativePath(path);
    return FutureBuilder<Uri>(
      future: _webUrl,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) return const ShellStatusView.splash();
        return WebViewHost(
          key: const ValueKey('web-host'),
          initialUrl: url,
          rpcServer: widget.rpcServer,
          themeMode: widget.themeMode,
          isOnline: widget.isOnline,
          pushPaths: _webPaths.stream,
          forceUpdate: widget.forceUpdate,
          onUpdate: widget.onUpdate,
          nativeLocation: native ? path : null,
          nativeChild: native ? child : null,
          onOpenNative: _router.go,
          onCloseNative: () => _router.go(_webPath),
          onNativeBack: _backFromNative,
        );
      },
    );
  }

  void _backFromNative() {
    if (_router.canPop()) {
      _router.pop();
    } else {
      _router.go(_settingPath);
    }
  }

  /// 푸시 알림이나 설정 화면에서 온 경로를 앱 화면과 웹 화면으로 나눠 연다.
  void _handlePushPath(String path) {
    if (!mounted) return;
    if (NativeShellPage.isNativePath(path)) {
      _router.go(path);
    } else {
      _openWeb(path);
    }
  }

  void _openWeb(String path) {
    _router.go(_webPath);
    _webPaths.add(path);
  }

  /// 약관에 동의한 신규 회원은 웹으로 들어가기 전에 권한 안내를 거친다.
  void _handleTermsAccepted() {
    _webUrl = widget.webUrlResolver.resolve();
    _router.go('/permissions');
  }

  void _handleAuthenticated() {
    _webUrl = widget.webUrlResolver.resolve();
    _router.refresh();
  }

  Future<_Access> _readAccess() async {
    // 로컬 인증 스냅샷만 본다. 첫 화면이 계정 활성 확인 네트워크 호출에
    // 막히지 않도록, 서버 동기화는 라이프사이클 훅에서 따로 이어진다.
    final token = await _tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) return _Access.signedOut;
    final status = (await _tokenStorage.getUserStatus())?.toUpperCase();
    if (status == 'PENDING') return _Access.pendingTerms;
    if (await _tokenStorage.getIsActive() == false) return _Access.signedOut;
    return _Access.active;
  }

  Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final location = state.matchedLocation;
    if (location == '/error') return null;
    try {
      return switch (await _readAccess()) {
        _Access.signedOut => location == '/auth' ? null : '/auth',
        _Access.pendingTerms =>
          location == '/auth' || location == '/terms' ? null : '/terms',
        _Access.active =>
          location == '/' || location == '/auth' || location == '/terms'
              ? _webPath
              : null,
      };
    } catch (error, stack) {
      AppLogger.error('Auth state resolution failed', error, stack);
      return '/error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: widget.themeMode,
      builder: (context, themeMode, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'ImHere',
        theme: ImHereAppTheme.light,
        darkTheme: ImHereAppTheme.dark,
        themeMode: themeMode,
        locale: const Locale('ko', 'KR'),
        supportedLocales: const [Locale('ko', 'KR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
