import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/auth/service/auth_state.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AuthState> authState(Ref ref) async {
  final tokenStorage = getIt<TokenStorageService>();
  final accessToken = await tokenStorage.getAccessToken();
  final hasToken = accessToken != null && accessToken.isNotEmpty;
  if (!hasToken) {
    AppLogger.debug('authStateProvider: no access token -> unauthenticated');
    return AuthState.unauthenticated;
  }

  final isPending = await tokenStorage.getPendingAuth();
  final userStatus = await tokenStorage.getUserStatus();
  final isPendingState = isPending || userStatus == 'PENDING';
  if (isPendingState) {
    AppLogger.debug(
      'authStateProvider: hasToken=$hasToken pending=$isPending userStatus=$userStatus -> pending',
    );
    return AuthState.pending;
  }

  final isActive = await tokenStorage.getIsActive();
  if (isActive == false) {
    AppLogger.debug(
      'authStateProvider: hasToken=$hasToken pending=$isPending userStatus=$userStatus isActive=$isActive -> inactive',
    );
    return AuthState.inactive;
  }

  AppLogger.debug(
    'authStateProvider: hasToken=$hasToken pending=$isPending userStatus=$userStatus isActive=$isActive -> authenticated',
  );
  return AuthState.authenticated;
}
