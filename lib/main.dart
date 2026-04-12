import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/router/router_provider.dart';
import 'package:iamhere/shared/component/theme/im_here_theme_data_dark.dart';
import 'package:iamhere/shared/component/theme/im_here_theme_data_light.dart';
import 'package:iamhere/shared/component/theme/theme_mode_provider.dart';
import 'package:iamhere/shared/firebase/firebase_service.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';
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
