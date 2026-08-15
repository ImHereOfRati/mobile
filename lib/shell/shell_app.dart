import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/auth/service/auth_session_sync_service.dart';
import 'package:iamhere/feature/auth/service/auth_invalidation_notifier.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/feature/auth/service/auth_login_coordinator.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/terms/service/terms_service.dart';
import 'package:iamhere/feature/auth/presentation/auth_flow_app.dart';
import 'package:iamhere/feature/geofence/background/geofence_delivery_pipeline.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_scheduler.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/integration/fcm/fcm_message_handler.dart';
import 'package:iamhere/shell/bridge/bridge_rpc_server.dart';
import 'package:iamhere/shell/shell_theme.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';
import 'package:iamhere/shell/web_url_resolver.dart';
import 'package:iamhere/shell/webview_host.dart';

class ShellApp extends StatefulWidget {
  final WebUrlResolver webUrlResolver;
  final BridgeRpcServer rpcServer;
  final ConnectivityProbe isOnline;
  final bool enablePush;
  final bool forceUpdate;
  final VoidCallback? onUpdate;

  const ShellApp({
    super.key,
    required this.webUrlResolver,
    required this.rpcServer,
    required this.isOnline,
    this.enablePush = true,
    this.forceUpdate = false,
    this.onUpdate,
  });

  @override
  State<ShellApp> createState() => _ShellAppState();
}

class _ShellAppState extends State<ShellApp> {
  static const _deliveryQueuePollInterval = Duration(seconds: 30);
  final StreamController<String> _pushPaths =
      StreamController<String>.broadcast();
  late Future<Uri?> _initialUrl;
  late final AppLifecycleListener _lifecycleListener;
  Timer? _deliveryRetryTimer;
  String _authInitialLocation = '/auth';

  @override
  void initState() {
    super.initState();
    _initialUrl = _prepareServiceUrl();
    getIt<AuthInvalidationNotifier>().addListener(_handleAuthInvalidation);
    if (widget.enablePush) {
      setupShellMessageTapHandler(_pushPaths.add);
    }
    _startDeliveryRetryTimer();
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _startDeliveryRetryTimer();
        unawaited(_drainDeliveryQueue());
        unawaited(_syncAuthSession());
        unawaited(_syncNativeGeofences());
      },
      onPause: _stopDeliveryRetryTimer,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncNativeGeofences());
      unawaited(_syncAuthSession());
    });
  }

  @override
  void dispose() {
    _stopDeliveryRetryTimer();
    getIt<AuthInvalidationNotifier>().removeListener(_handleAuthInvalidation);
    _lifecycleListener.dispose();
    unawaited(_pushPaths.close());
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

  Future<void> _syncAuthSession() async {
    if (!getIt.isRegistered<AuthSessionSyncService>()) return;
    try {
      await getIt<AuthSessionSyncService>().syncIfSignedIn();
    } catch (error, stack) {
      AppLogger.error('Auth session sync failed', error, stack);
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

  void _retryBootstrap() {
    _reloadInitialUrl();
  }

  void _handleAuthInvalidation() {
    if (!mounted) return;
    _authInitialLocation = '/auth';
    final initialUrl = Future<Uri?>.value(null);
    setState(() {
      _initialUrl = initialUrl;
    });
  }

  void _reloadInitialUrl() {
    if (!mounted) return;
    final initialUrl = _prepareServiceUrl();
    setState(() {
      _initialUrl = initialUrl;
    });
  }

  Future<Uri?> _prepareServiceUrl() async {
    // Resolve the local auth snapshot first so the first screen is not blocked
    // by the active-session network check. Auth sync continues in the
    // background from the lifecycle/post-frame hooks.
    final storage = getIt<TokenStorageService>();
    final token = await storage.getAccessToken();
    final status = (await storage.getUserStatus())?.toUpperCase();
    final isActive = await storage.getIsActive();
    if (token == null || token.isEmpty) {
      _authInitialLocation = '/auth';
      return null;
    }
    if (status == 'PENDING') {
      _authInitialLocation = '/terms';
      return null;
    }
    if (isActive == false) {
      _authInitialLocation = '/auth';
      return null;
    }
    return widget.webUrlResolver.resolve();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ImHere',
      theme: ShellTheme.light,
      darkTheme: ShellTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: FutureBuilder<Uri?>(
        future: _initialUrl,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ShellStatusView.fatalError(onRetry: _retryBootstrap);
          }
          final url = snapshot.data;
          if (snapshot.connectionState != ConnectionState.done) {
            return const ShellStatusView.splash();
          }
          if (url == null) {
            return AuthFlowApp(
              key: ValueKey(_authInitialLocation),
              initialLocation: _authInitialLocation,
              authLoginCoordinator: getIt<AuthLoginCoordinator>(),
              authService: getIt<AuthService>(),
              termsService: getIt<TermsService>(),
              onAuthenticated: _reloadInitialUrl,
            );
          }
          return WebViewHost(
            initialUrl: url,
            rpcServer: widget.rpcServer,
            isOnline: widget.isOnline,
            pushPaths: _pushPaths.stream,
            forceUpdate: widget.forceUpdate,
            onUpdate: widget.onUpdate,
          );
        },
      ),
    );
  }
}
