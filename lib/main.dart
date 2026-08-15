import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:iamhere/common/config/app_env.dart';
import 'package:iamhere/common/config/app_origin.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/geofence/background/geofence_retry_workmanager.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/integration/firebase/firebase_remote_service.dart';
import 'package:iamhere/integration/firebase/firebase_service.dart';
import 'package:iamhere/integration/fcm/service/fcm_token_service.dart';
import 'package:iamhere/shell/bridge/shell_bridge_factory.dart';
import 'package:iamhere/shell/app_version_policy.dart';
import 'package:iamhere/shell/shell_app.dart';
import 'package:iamhere/shell/view/shell_status_view.dart';
import 'package:iamhere/shell/web_url_resolver.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(_initializeBackgroundWork());
  _configureSystemChrome();

  try {
    final bootstrap = await _initializeAppDependencies();
    runApp(
      ProviderScope(
        child: ShellApp(
          webUrlResolver: WebUrlResolver(
            loadRemoteUrl: () async => bootstrap.remoteConfig?.webAppUrlOrNull,
          ),
          rpcServer: ShellBridgeFactory.create(),
          isOnline: hasNetworkConnection,
          enablePush: bootstrap.firebaseReady,
          forceUpdate: bootstrap.forceUpdate,
          onUpdate: bootstrap.storeUrl == null
              ? null
              : () => launchUrl(
                  bootstrap.storeUrl!,
                  mode: LaunchMode.externalApplication,
                ),
        ),
      ),
    );
  } catch (error, stack) {
    AppLogger.error('Application bootstrap failed', error, stack);
    runApp(const _BootstrapFailureApp());
  }
}

Future<bool> hasNetworkConnection() async {
  try {
    final addresses = await InternetAddress.lookup(
      AppOrigin.host,
    ).timeout(const Duration(seconds: 3));
    return addresses.isNotEmpty;
  } on TimeoutException {
    return false;
  } on SocketException {
    return false;
  }
}

void _configureSystemChrome() {
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

Future<_BootstrapResult> _initializeAppDependencies() async {
  await AppEnv.ensureLoaded();

  FirebaseRemoteService? remoteConfig;
  var firebaseReady = false;
  try {
    await FirebaseService().initialize();
    remoteConfig = FirebaseService().remoteConfig;
    firebaseReady = true;
  } catch (error, stack) {
    AppLogger.error(
      'Firebase initialization failed; local shell fallback will continue',
      error,
      stack,
    );
  }

  await enrollBaseUrlGlobally(
    baseUrl: remoteConfig?.baseUrlOrNull ?? AppOrigin.origin,
  );
  if (firebaseReady) {
    getIt<FcmTokenService>().startTokenRefreshListener();
  }

  final kakaoKey = AppEnv.maybe('KAKAO_NATIVE_APP_KEY');
  if (kakaoKey != null) {
    KakaoSdk.init(nativeAppKey: kakaoKey);
  }
  final packageInfo = await PackageInfo.fromPlatform();
  final storeUrlRaw = Platform.isIOS
      ? remoteConfig?.iosStoreUrlOrNull
      : remoteConfig?.androidStoreUrlOrNull ??
            'https://play.google.com/store/apps/details'
                '?id=com.kdongsu5509.iamhere';
  final storeUrl = storeUrlRaw == null ? null : Uri.tryParse(storeUrlRaw);
  return _BootstrapResult(
    remoteConfig: remoteConfig,
    firebaseReady: firebaseReady,
    forceUpdate:
        storeUrl != null &&
        AppVersionPolicy.requiresUpdate(
          currentVersion: packageInfo.version,
          minimumVersion: remoteConfig?.minimumAppVersionOrNull,
        ),
    storeUrl: storeUrl,
  );
}

Future<void> _initializeBackgroundWork() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(
    geofenceRetryCallbackDispatcher,
    isInDebugMode: false,
  );
}

class _BootstrapResult {
  final FirebaseRemoteService? remoteConfig;
  final bool firebaseReady;
  final bool forceUpdate;
  final Uri? storeUrl;

  const _BootstrapResult({
    required this.remoteConfig,
    required this.firebaseReady,
    required this.forceUpdate,
    required this.storeUrl,
  });
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ShellStatusView.fatalError(onRetry: SystemNavigator.pop),
    );
  }
}
