import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/model/service/account/auth_account_sync_service.dart';
import 'package:iamhere/feature/auth/view/page/auth_page.dart';
import 'package:iamhere/feature/auth/viewmodel/auth_invalidation_notifier.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/setting/model/service/setting_status_service_interface.dart';
import 'package:iamhere/feature/setting/model/service/user_me_service_interface.dart';
import 'package:iamhere/feature/setting/view/page/setting_page.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/feature/setting/view/page/agreements_page.dart';
import 'package:iamhere/feature/terms/view/page/terms_page.dart';
import 'package:iamhere/feature/friend/model/service/device_contact_service.dart';
import 'package:iamhere/feature/friend/model/service/friend_service.dart';
import 'package:iamhere/feature/friend/view/page/device_contact_edit_page.dart';
import 'package:iamhere/feature/friend/view/page/friend_page.dart';
import 'package:iamhere/feature/friend/view/page/friend_requests_page.dart';
import 'package:iamhere/feature/friend/view/page/friend_restrictions_page.dart';
import 'package:iamhere/feature/record/model/service/activity_log_service.dart';
import 'package:iamhere/feature/record/model/service/server_notification_service.dart';
import 'package:iamhere/feature/record/view/page/record_detail_pages.dart';
import 'package:iamhere/feature/record/view/page/record_page.dart';
import 'package:iamhere/feature/record/view/page/send_history_page.dart';
import 'package:iamhere/feature/record/view/page/server_notifications_page.dart';
import 'package:iamhere/feature/geofence/delivery/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_scheduler.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/model/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/user_permission/service/locate_permission_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_guide_service.dart';
import 'package:iamhere/feature/user_permission/service/permission_onboarding_service.dart';
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
    notificationAvailable: widget.enablePush,
  );
  final _onboarding = PermissionOnboardingService(
    getIt<FlutterSecureStorage>(),
  );
  bool _onboardingDone = false;
  final _loginCoordinator = getIt<SocialLoginService>();
  final _userMeService = getIt<UserMeServiceInterface>();
  final _statusService = getIt<SettingStatusServiceInterface>();
  final _friendService = getIt<FriendService>();
  final _contactService = getIt<DeviceContactService>();
  final _activityLog = getIt<ActivityLogService>();
  final _serverNotifications = getIt<ServerNotificationService>();

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
          ),
        ),
        GoRoute(
          path: '/terms',
          builder: (_, __) => TermsPage(
            authService: _authService,
            termsService: _termsService,
            onDone: _handleAuthenticated,
          ),
        ),
        GoRoute(
          path: '/permissions',
          builder: (_, __) => PermissionGuidePage(
            service: _permissionGuideService,
            onDone: _completeOnboarding,
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
                ),
              ],
            ),
            ..._friendRoutes(),
            ..._recordRoutes(),
          ],
        ),
      ],
    );
  }

  // 하위 화면은 위로 쌓지 않고 같은 단계의 형제 라우트로 둔다. 어느 화면에서
  // 들어와도 아래에 엉뚱한 목록 화면이 깔리지 않게 하기 위해서다. 뒤로 가기는
  // _backFromNative가 부모 경로로 돌려보낸다.
  List<RouteBase> _friendRoutes() => [
    GoRoute(
      path: '/friend',
      pageBuilder: (_, __) => NoTransitionPage(child: _friendPage()),
    ),
    GoRoute(
      path: '/friend/add',
      builder: (_, __) => _friendPage(finderInitiallyOpen: true),
    ),
    GoRoute(
      path: '/friend/requests',
      builder: (_, __) => FriendRequestsPage(friendService: _friendService),
    ),
    GoRoute(
      path: '/friend/restrictions',
      builder: (_, __) => FriendRestrictionsPage(friendService: _friendService),
    ),
    GoRoute(
      path: '/friend/device-contact/:contactId/edit',
      builder: (_, state) => DeviceContactEditPage(
        friendService: _friendService,
        contactService: _contactService,
        contactId: int.tryParse(state.pathParameters['contactId']!) ?? -1,
      ),
    ),
  ];

  List<RouteBase> _recordRoutes() => [
    GoRoute(
      path: '/record',
      pageBuilder: (_, __) => NoTransitionPage(
        child: RecordPage(
          activityLog: _activityLog,
          friendService: _friendService,
        ),
      ),
    ),
    GoRoute(
      path: '/record/notifications',
      builder: (_, __) =>
          ServerNotificationsPage(service: _serverNotifications),
    ),
    GoRoute(
      path: '/record/notifications/:id',
      builder: (_, state) => NotificationDetailPage(
        activityLog: _activityLog,
        notificationId: int.tryParse(state.pathParameters['id']!) ?? -1,
      ),
    ),
    GoRoute(
      path: '/record/send-history',
      builder: (_, __) => SendHistoryPage(activityLog: _activityLog),
    ),
    GoRoute(
      path: '/record/send-history/:id',
      builder: (_, state) => SendHistoryDetailPage(
        activityLog: _activityLog,
        recordId: int.tryParse(state.pathParameters['id']!) ?? -1,
      ),
    ),
    // 예전 웹 경로. 푸시 알림에 남아 있을 수 있어 새 경로로 돌려보낸다.
    GoRoute(
      path: '/record/friend-requests',
      redirect: (_, __) => '/friend/requests',
    ),
    GoRoute(
      path: '/record/server-notifications',
      redirect: (_, __) => '/record/notifications',
    ),
  ];

  Widget _friendPage({bool finderInitiallyOpen = false}) => FriendPage(
    friendService: _friendService,
    contactService: _contactService,
    finderInitiallyOpen: finderInitiallyOpen,
  );

  Widget _settingPage() => SettingPage(
    userMeService: _userMeService,
    tokenStorage: _tokenStorage,
    statusService: _statusService,
    themeMode: widget.themeMode,
    saveTheme: widget.saveTheme ?? ThemePreferenceService().save,
    onOpenSendHistory: () => _router.push('/record/send-history'),
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
      return;
    }
    final current = _router.routeInformationProvider.value.uri.path;
    _router.go(NativeShellPage.parentOf(current) ?? _settingPath);
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

  /// 권한 안내를 마치거나 건너뛰면 다시 띄우지 않고 앱으로 들어간다.
  Future<void> _completeOnboarding() async {
    try {
      await _onboarding.markCompleted();
    } catch (error, stack) {
      AppLogger.error('Permission onboarding flag write failed', error, stack);
    }
    _onboardingDone = true;
    _router.go('/');
  }

  /// 권한 안내를 더 보여 주지 않아도 되는지 확인한다.
  ///
  /// 이 기기에서 이미 안내를 마쳤거나, 안내할 권한이 모두 허용돼 있으면
  /// 안내 화면을 건너뛴다.
  Future<bool> _isOnboardingDone() async {
    if (_onboardingDone) return true;
    var done = await _onboarding.isCompleted();
    if (!done && await _allPermissionsGranted()) {
      await _onboarding.markCompleted();
      done = true;
    }
    return _onboardingDone = done;
  }

  Future<bool> _allPermissionsGranted() async {
    try {
      return await _permissionGuideService.areAllGranted();
    } catch (error, stack) {
      AppLogger.error('Permission status check failed', error, stack);
      return false;
    }
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

  /// 로그인을 마친 사용자는 권한 안내가 필요하면 먼저 거치고, 그 뒤에 앱으로 들어간다.
  Future<String?> _activeRedirect(String location) async {
    if (!await _isOnboardingDone()) {
      return location == '/permissions' ? null : '/permissions';
    }
    const entryPaths = {'/', '/auth', '/terms', '/permissions'};
    return entryPaths.contains(location) ? _webPath : null;
  }

  Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final location = state.matchedLocation;
    if (location == '/error') return null;
    try {
      return switch (await _readAccess()) {
        _Access.signedOut => location == '/auth' ? null : '/auth',
        _Access.pendingTerms =>
          location == '/auth' || location == '/terms' ? null : '/terms',
        _Access.active => await _activeRedirect(location),
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
