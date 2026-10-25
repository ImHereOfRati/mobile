import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/auth/view/page/auth_page.dart';
import 'package:iamhere/feature/terms/view/page/terms_page.dart';
import 'package:iamhere/feature/auth/model/service/login/social_login_service.dart';
import 'package:iamhere/feature/auth/model/service/login/auth_service.dart';
import 'package:iamhere/feature/terms/model/service/terms_service.dart';
import 'package:iamhere/theme/imhere_theme.dart';

class AuthFlowApp extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final String initialLocation;
  final SocialLoginService authLoginCoordinator;
  final AuthService authService;
  final TermsService termsService;
  final Future<void> Function() requestLocationPermission;
  final Future<void> Function()? requestNotificationPermission;
  final ThemeMode themeMode;

  const AuthFlowApp({
    super.key,
    required this.onAuthenticated,
    required this.authLoginCoordinator,
    required this.authService,
    required this.termsService,
    required this.requestLocationPermission,
    this.requestNotificationPermission,
    this.themeMode = ThemeMode.system,
    this.initialLocation = '/auth',
  });

  @override
  State<AuthFlowApp> createState() => _AuthFlowAppState();
}

class _AuthFlowAppState extends State<AuthFlowApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => AuthPage(
          authLoginCoordinator: widget.authLoginCoordinator,
          onAuthenticated: widget.onAuthenticated,
          requestLocationPermission: widget.requestLocationPermission,
          requestNotificationPermission: widget.requestNotificationPermission,
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => TermsPage(
          authService: widget.authService,
          termsService: widget.termsService,
          onDone: widget.onAuthenticated,
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ImHere',
      theme: ImHereAppTheme.light,
      darkTheme: ImHereAppTheme.dark,
      themeMode: widget.themeMode,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
