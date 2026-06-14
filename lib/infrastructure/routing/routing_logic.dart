import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';

import 'auth_redirect_policy.dart';

class RouterLogic {
  static const _redirectPolicy = AuthRedirectPolicy();

  static String? handleRedirect(Ref ref, GoRouterState state) {
    final authState = ref.read(authStateProvider);

    if (authState.isLoading) return null;
    if (authState.hasError) return null;

    return _redirectPolicy.resolve(
      authState: authState.asData?.value,
      matchedLocation: state.matchedLocation,
      requestedUri: state.uri,
    );
  }
}
