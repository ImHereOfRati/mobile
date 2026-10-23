import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/auth/presentation/auth_flow_controller.dart';
import 'package:iamhere/feature/auth/presentation/auth_page.dart';
import 'package:iamhere/feature/auth/presentation/terms_page.dart';
import 'package:iamhere/feature/auth/service/auth_login_coordinator.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/terms/service/terms_service.dart';
import 'package:iamhere/shell/shell_theme.dart';

class AuthFlowApp extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final String initialLocation;
  final AuthLoginCoordinator authLoginCoordinator;
  final AuthService authService;
  final TermsService termsService;
  final Future<void> Function() requestLocationPermission;

  const AuthFlowApp({
    super.key,
    required this.onAuthenticated,
    required this.authLoginCoordinator,
    required this.authService,
    required this.termsService,
    required this.requestLocationPermission,
    this.initialLocation = '/auth',
  });

  @override
  State<AuthFlowApp> createState() => _AuthFlowAppState();
}

class _AuthFlowAppState extends State<AuthFlowApp> {
  late final AuthFlowDependencies _authDependencies = AuthFlowDependencies(
    widget.authLoginCoordinator,
    widget.authService,
  );

  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    routes: [
      GoRoute(
        path: '/auth',
        builder: (_, __) => AuthPage(
          dependencies: _authDependencies,
          onAuthenticated: widget.onAuthenticated,
          requestLocationPermission: widget.requestLocationPermission,
        ),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => TermsPage(
          dependencies: _authDependencies,
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
      theme: ShellTheme.light,
      darkTheme: ShellTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
