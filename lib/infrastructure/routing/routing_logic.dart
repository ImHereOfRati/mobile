import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';
import 'package:iamhere/feature/user_permission/view_model/auto_send_readiness_provider.dart';

import 'auth_redirect_policy.dart';

class RouterLogic {
  static const _redirectPolicy = AuthRedirectPolicy();

  static String? handleRedirect(Ref ref, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final readiness = ref.read(autoSendReadinessProvider);

    if (authState.isLoading) {
      AppLogger.debug(
        'RouterLogic: authState loading matched=${state.matchedLocation} requested=${state.uri}',
      );
      return null;
    }
    if (authState.hasError) {
      AppLogger.warning(
        'RouterLogic: authState error matched=${state.matchedLocation} requested=${state.uri}',
      );
      return null;
    }

    final redirect = _redirectPolicy.resolve(
      authState: authState.asData?.value,
      autoSendReady: readiness.isReady,
      matchedLocation: state.matchedLocation,
      requestedUri: state.uri,
    );
    AppLogger.debug(
      'RouterLogic: authState=${authState.asData?.value} matched=${state.matchedLocation} requested=${state.uri} -> ${redirect ?? 'null'}',
    );
    return redirect;
  }
}
