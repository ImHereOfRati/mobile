import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/core/router/router_provider.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/missing_background_location_exception.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/integration/fcm/fcm_message_handler.dart';
import 'package:iamhere/integration/firebase/firebase_service.dart';
import 'package:iamhere/shared/component/theme/im_here_theme_data_dark.dart';
import 'package:iamhere/shared/component/theme/im_here_theme_data_light.dart';
import 'package:iamhere/shared/component/theme/theme_mode_provider.dart';
import 'package:iamhere/shared/component/view_component/initialization_error_app.dart';
import 'package:iamhere/shared/util/app_logger.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureSystemChrome();
  try {
    await _initializeAppDependencies();
    runApp(const ProviderScope(child: ImHereApp()));
  } catch (e, stack) {
    AppLogger.error('상부 의존성 초기화 실패', e, stack);
    runApp(const InitializationErrorApp());
  }
}

void _configureSystemChrome() {
  SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

class ImHereApp extends ConsumerStatefulWidget {
  const ImHereApp({super.key});

  @override
  ConsumerState<ImHereApp> createState() => _ImHereAppState();
}

class _ImHereAppState extends ConsumerState<ImHereApp> {
  static final String _appTitle = "ImHere";
  static const Locale _fixedLocale = Locale('ko', 'KR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setupMessageTapHandler(ref.read(routerProvider));
      await _syncNativeGeofencesOnStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final routerConfig = ref.watch(routerProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    return ScreenUtilInit(
      designSize: const Size(402, 874),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: _appTitle,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          routerConfig: routerConfig,
          locale: _fixedLocale,
          supportedLocales: const [_fixedLocale],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          localeResolutionCallback: (_, __) => _fixedLocale,
        );
      },
    );
  }
}

Future<void> _initializeAppDependencies() async {
  await _initializeDotEnvFile();
  await FirebaseService().initialize();
  await _initializeBaseUrl();
  _initializeKakaoSdk();
  // NaverMap SDK 는 위젯 빌드 전에 init 완료가 필수라 pre-runApp 단계에서 처리한다.
  await _initializeFlutterNaverMap();
}

void _initializeKakaoSdk() {
  final kakaoNativeAppKey = 'KAKAO_NATIVE_APP_KEY';
  KakaoSdk.init(nativeAppKey: dotenv.env[kakaoNativeAppKey]);
}

/// 앱 시작 시 DB 의 활성 지오펜스를 OS 네이티브 지오펜스와 재동기화한다.
/// 재부팅/앱 재설치 후 OS 등록 상태와 DB 가 어긋나는 경우를 바로잡는다.
Future<void> _syncNativeGeofencesOnStart() async {
  try {
    final registrar = getIt<NativeGeofenceRegistrarInterface>();
    await registrar.initialize();

    final repo = getIt<GeofenceLocalRepository>();
    final all = await repo.findAll();
    final active = all.where((g) => g.isActive).toList();
    await registrar.syncAll(active);
  } on MissingBackgroundLocationException catch (e) {
    // 첫 실행 또는 권한 미허용 상태에서는 정상 시나리오. 사용자가 가이드 뷰에서
    // '항상 허용' 으로 상향한 뒤 토글/저장 시점에 자연스럽게 등록된다.
    AppLogger.warning('OS 지오펜스 초기 동기화 보류: 권한 부족 (${e.state.name})');
  } catch (e) {
    AppLogger.error('OS 지오펜스 초기 동기화 실패', e);
  }
}

Future<void> _initializeBaseUrl() async {
  final localServerUrlForAOS = 'http://10.0.2.2:8080';
  final String? remoteUrl = FirebaseService().remoteConfig.baseUrlOrNull;

  final String finalBaseUrl = remoteUrl ?? localServerUrlForAOS;
  await enrollBaseUrlGlobally(baseUrl: finalBaseUrl);
}

Future<void> _initializeDotEnvFile() async {
  final dotenvFileName = 'iam_here_flutter_secret.env';
  await dotenv.load(fileName: dotenvFileName);
}

Future<void> _initializeFlutterNaverMap() async {
  final naverMapClientIdKey = 'NAVER_MAP_CLIENT_ID';

  await FlutterNaverMap().init(
    clientId: dotenv.env[naverMapClientIdKey],
    onAuthFailed: (ex) {
      AppLogger.error('네이버 지도 인증 실패 상세', ex);
      switch (ex) {
        case NQuotaExceededException(:final message):
          AppLogger.warning('사용량 초과 (message: $message)');
          break;
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          AppLogger.error('인증 실패 (패키지명이나 클라이언트 ID를 확인하세요)', ex);
          break;
      }
    },
  );
}
