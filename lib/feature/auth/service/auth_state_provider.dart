import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/auth/model/auth_state.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_state_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AuthState> authState(Ref ref) async {
  final accessToken = await getIt<TokenStorageService>().getAccessToken();
  final hasToken = accessToken != null && accessToken.isNotEmpty;
  return hasToken ? AuthState.authenticated : AuthState.unauthenticated;
}
