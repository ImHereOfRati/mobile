import 'package:iamhere/infrastructure/di/di_setup.dart';
import 'package:iamhere/feature/auth/service/auth_state.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AuthState> authState(Ref ref) async {
  final tokenStorage = getIt<TokenStorageService>();
  final accessToken = await tokenStorage.getAccessToken();
  final hasToken = accessToken != null && accessToken.isNotEmpty;
  if (!hasToken) return AuthState.unauthenticated;

  final isPending = await tokenStorage.getPendingAuth();
  if (isPending || await tokenStorage.getUserStatus() == 'PENDING') {
    return AuthState.pending;
  }

  final isActive = await tokenStorage.getIsActive();
  if (isActive == false) return AuthState.inactive;

  return AuthState.authenticated;
}
