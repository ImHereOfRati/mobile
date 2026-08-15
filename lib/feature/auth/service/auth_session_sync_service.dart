import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/auth/service/invalid_auth_session_exception.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/feature/setting/service/user_me_service_interface.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthSessionSyncService {
  final TokenStorageService _tokenStorage;
  final UserMeServiceInterface _userMeService;

  AuthSessionSyncService(this._tokenStorage, this._userMeService);

  Future<bool> syncIfSignedIn() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      AppLogger.debug('AuthSessionSync: no access token -> skip');
      return false;
    }

    // Newly authenticated users are intentionally PENDING until the WebView
    // collects terms consent. `/api/users/my` is active-user-only, so calling
    // it here would return 403 and incorrectly clear a valid pending session.
    final storedUserStatus = await _tokenStorage.getUserStatus();
    if (storedUserStatus?.toUpperCase() == 'PENDING') {
      AppLogger.debug(
        'AuthSessionSync: pending session -> skip active user sync',
      );
      return true;
    }

    AppLogger.debug('AuthSessionSync: syncing signed-in session');

    try {
      final myInfo = await _userMeService.fetchMyInfo();
      if (myInfo == null) {
        AppLogger.warning('AuthSessionSync: /api/users/my returned null');
        return false;
      }

      // CompactUserResponse currently has no status fields. Preserve the
      // authenticated snapshot instead of silently turning PENDING into ACTIVE.
      final effectiveUserStatus =
          myInfo.userStatus ?? await _tokenStorage.getUserStatus();
      final effectiveIsActive =
          myInfo.isActive ?? await _tokenStorage.getIsActive();
      AppLogger.debug(
        'AuthSessionSync: myInfo.userStatus=${myInfo.userStatus} '
        'myInfo.isActive=${myInfo.isActive} '
        'effectiveUserStatus=$effectiveUserStatus '
        'effectiveIsActive=$effectiveIsActive',
      );
      await _tokenStorage.saveAuthSnapshot(
        userStatus: effectiveUserStatus,
        isActive: effectiveIsActive,
      );
      AppLogger.debug('AuthSessionSync: snapshot saved');
      return true;
    } on InvalidAuthSessionException catch (error) {
      // The account may have been deleted or the stored JWT may be revoked.
      // Do not let the WebView observe the stale pending session on startup.
      await _tokenStorage.deleteAllTokens();
      AppLogger.warning(
        'AuthSessionSync: invalid session (${error.statusCode}); local auth cleared',
      );
      return false;
    } catch (e, st) {
      AppLogger.error('인증 세션 동기화 실패', e, st);
      return false;
    }
  }
}
