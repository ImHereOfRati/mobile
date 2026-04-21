import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/core/router/router_provider.dart';
import 'package:iamhere/feature/geofence/repository/geofence_local_repository.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/integration/fcm/fcm_message_handler.dart';
import 'package:iamhere/shared/component/theme/im_here_theme_data_dark.dart';
import 'package:iamhere/shared/component/theme/im_here_theme_data_light.dart';
import 'package:iamhere/shared/component/theme/theme_mode_provider.dart';
import 'package:iamhere/integration/firebase/firebase_service.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeAppDependencies();
  runApp(const ProviderScope(child: ImHereApp()));
}

class ImHereApp extends ConsumerStatefulWidget {
  const ImHereApp({super.key});

  @override
  ConsumerState<ImHereApp> createState() => _ImHereAppState();
}

class _ImHereAppState extends ConsumerState<ImHereApp> {
  static final String _appTitle = "ImHere";

  @override
  void initState() {
    super.initState();
    // 라우터가 구축된 뒤(첫 프레임 이후) 알림 탭 핸들러를 등록한다.
    // getInitialMessage()는 콜드 스타트 직후 한 번만 유효하므로
    // 이 시점에 반드시 호출해야 한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupMessageTapHandler(ref.read(routerProvider));
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
          title: _appTitle,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          routerConfig: routerConfig,
        );
      },
    );
  }
}

Future<void> _initializeAppDependencies() async {
  final String kakaoNativeAppKey = 'KAKAO_NATIVE_APP_KEY';

  await _initializeDotEnvFile();
  await FirebaseService().initialize();
  await _initializeBaseUrl();
  KakaoSdk.init(nativeAppKey: dotenv.env[kakaoNativeAppKey]);
  await _initializeFlutterNaverMap();
  await _syncNativeGeofencesOnStart();
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
  } catch (e) {
    debugPrint('OS 지오펜스 초기 동기화 실패: $e');
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
      switch (ex) {
        case NQuotaExceededException(:final message):
          debugPrint("사용량 초과 (message: $message)");
          break;
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          debugPrint("인증 실패: $ex");
          break;
      }
    },
  );
}
