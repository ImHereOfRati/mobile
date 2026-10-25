import 'package:iamhere/core/util/app_logger.dart';
import 'package:iamhere/feature/auth/model/exception/invalid_auth_state_exception.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/feature/setting/model/service/user_me_service_interface.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthAccountSyncService {
  final TokenStorageService _tokenStorage;
  final UserMeServiceInterface _userMeService;

  AuthAccountSyncService(this._tokenStorage, this._userMeService);

  Future<bool> syncIfSignedIn() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      AppLogger.debug('AuthAccountSync: no access token -> skip');
      return false;
    }

    // Newly authenticated users are intentionally PENDING until the WebView
    // collects terms consent. `/api/users/my` is active-user-only, so calling
    // it here would return 403 and incorrectly clear a valid pending account.
    final storedUserStatus = await _tokenStorage.getUserStatus();
    if (storedUserStatus?.toUpperCase() == 'PENDING') {
      AppLogger.debug(
        'AuthAccountSync: pending account -> skip active user sync',
      );
      return true;
    }

    AppLogger.debug('AuthAccountSync: syncing signed-in account');

    try {
      final myInfo = await _userMeService.fetchMyInfo();
      if (myInfo == null) {
        AppLogger.warning('AuthAccountSync: /api/users/my returned null');
        return false;
      }

      // CompactUserResponse currently has no status fields. Preserve the
      // authenticated snapshot instead of silently turning PENDING into ACTIVE.
      final effectiveUserStatus =
          myInfo.userStatus ?? await _tokenStorage.getUserStatus();
      final effectiveIsActive =
          myInfo.isActive ?? await _tokenStorage.getIsActive();
      AppLogger.debug(
        'AuthAccountSync: myInfo.userStatus=${myInfo.userStatus} '
        'myInfo.isActive=${myInfo.isActive} '
        'effectiveUserStatus=$effectiveUserStatus '
        'effectiveIsActive=$effectiveIsActive',
      );
      await _tokenStorage.saveAuthSnapshot(
        userStatus: effectiveUserStatus,
        isActive: effectiveIsActive,
      );
      AppLogger.debug('AuthAccountSync: snapshot saved');
      return true;
    } on InvalidAuthStateException catch (error) {
      // The account may have been deleted or the stored JWT may be revoked.
      // Do not let the WebView observe the stale pending account on startup.
      await _tokenStorage.deleteAllTokens();
      AppLogger.warning(
        'AuthAccountSync: invalid authentication state (${error.statusCode}); local auth cleared',
      );
      return false;
    } catch (e, st) {
      AppLogger.error('Auth account state sync failed', e, st);
      return false;
    }
  }
}
