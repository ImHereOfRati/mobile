import 'package:iamhere/core/network/properties/http_status_code.dart';
import 'package:iamhere/core/result/error_analyst.dart';
import 'package:iamhere/feature/auth/model/exception/auth_exception.dart';
import 'package:iamhere/feature/auth/model/repository/auth_repository.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/auth/model/type/login_result.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthService {
  AuthService(this._authRepository, this._tokenStorage);

  final AuthRepository _authRepository;
  final TokenStorageService _tokenStorage;

  Future<void> activateWithTerms(List<Map<String, Object?>> consents) async {
    await _authRepository.acceptTerms(consents);
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw TokenStorageException('Refresh token is missing after activation.');
    }

    final session = await _authRepository.refresh(refreshToken);
    await _saveSession(
      session.response.accessToken,
      session.response.refreshToken,
    );
    await _tokenStorage.saveAuthSnapshot(
      userStatus: session.response.userStatus ?? 'ACTIVE',
      isActive: session.response.isActive ?? true,
    );
  }

  Future<MemberState> sendIdTokenToServer(
    String idToken, {
    required String nonce,
    OauthProvider provider = OauthProvider.kakao,
  }) async {
    try {
      _validateCredentials(idToken, nonce);
      final session = await _authRepository.authenticate(
        idToken: idToken,
        nonce: nonce,
        provider: provider,
      );
      final response = session.response;
      await _saveSession(response.accessToken, response.refreshToken);
      await _tokenStorage.saveAuthSnapshot(
        userStatus: response.userStatus,
        isActive: response.isActive,
      );

      if (response.userStatus?.toUpperCase() == 'PENDING') {
        return MemberState.pending;
      }
      if (session.statusCode == HttpStatusCode.created) {
        return MemberState.newUser;
      }
      return MemberState.existingUser;
    } catch (error, stackTrace) {
      ErrorAnalyst.log(error.toString(), stackTrace);
      rethrow;
    }
  }

  void _validateCredentials(String idToken, String nonce) {
    if (idToken.trim().isEmpty) throw InvalidTokenException();
    if (nonce.trim().isEmpty) throw InvalidNonceException();
  }

  Future<void> _saveSession(String accessToken, String refreshToken) async {
    try {
      await _tokenStorage.saveAccessToken(accessToken);
      await _tokenStorage.saveRefreshToken(refreshToken);
    } catch (error, stackTrace) {
      throw TokenStorageException(error.toString(), stackTrace: stackTrace);
    }
  }
}
