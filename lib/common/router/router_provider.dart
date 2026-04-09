import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/auth/service/auth_state_provider.dart';
import 'package:iamhere/common/router/routers.dart';
import 'package:iamhere/user_permission/view_model/user_permission_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    refreshListenable: _createNotifier(ref),

    // initialLocation: '/user-permission',
    initialLocation: '/terms-consent',
    // redirect: (context, state) => RouterLogic.handleRedirect(ref, state),
    routes: appRoutes,
    errorBuilder: (_, __) => const Center(child: Text("Page Not Found")),
  );
}

ValueNotifier<void> _createNotifier(Ref ref) {
  final notifier = ValueNotifier<void>(null);

  ref.listen(
    userPermissionViewModelProvider,
    (_, __) => notifier.notifyListeners(),
  );
  ref.listen(authStateProvider, (_, __) => notifier.notifyListeners());

  return notifier;
}
