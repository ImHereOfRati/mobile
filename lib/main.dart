import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/router/router_provider.dart';
import 'package:iamhere/common/theme/im_here_theme_data_light.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/core/firebase/firebase_service.dart';
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
  @override
  Widget build(BuildContext context) {
    final routerConfig = ref.watch(routerProvider);
    return ScreenUtilInit(
      designSize: const Size(402, 874),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'ImHere',
          theme: lightTheme,
          routerConfig: routerConfig,
        );
      },
    );
  }
}

Future<void> _initializeAppDependencies() async {
  final dotenvFileName = 'iam_here_flutter_secret.env';
  await dotenv.load(fileName: dotenvFileName);

  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  final String? remoteUrl = firebaseService.remoteConfig.baseUrlOrNull;
  final String fallbackUrl = 'http://10.0.2.2:8080';

  final String finalBaseUrl = remoteUrl ?? fallbackUrl;

  await configureDependencies(baseUrl: finalBaseUrl);

  KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']);
  await _initializeFlutterNaverMap();
}

Future<void> _initializeFlutterNaverMap() async {
  await FlutterNaverMap().init(
    clientId: dotenv.env['NAVER_MAP_CLIENT_ID'],
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
