import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/core/router/routers.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'routing_logic.dart';

part 'router_provider.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    refreshListenable: _createNotifier(ref),

    initialLocation: AppRoutes.auth,
    redirect: (context, state) => RouterLogic.handleRedirect(ref, state),
    routes: appRoutes,
    errorBuilder: (_, __) => const Center(child: Text("Page Not Found")),
  );
}

ValueNotifier<void> _createNotifier(Ref ref) {
  final notifier = ValueNotifier<void>(null);
  ref.listen(authStateProvider, (_, __) => notifier.notifyListeners());
  return notifier;
}
