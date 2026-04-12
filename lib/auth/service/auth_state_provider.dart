import 'package:iamhere/auth/model/auth_state.dart';
import 'package:iamhere/auth/service/token_storage_service.dart';
import 'package:iamhere/shared/infrastructure/di/di_setup.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

/// 현재 인증 상태를 제공하는 Provider.
@Riverpod(keepAlive: true)
Future<AuthState> authState(Ref ref) async {
  final accessToken = await getIt<TokenStorageService>().getAccessToken();
  final hasToken = accessToken != null && accessToken.isNotEmpty;
  return hasToken ? AuthState.authenticated : AuthState.unauthenticated;
}
