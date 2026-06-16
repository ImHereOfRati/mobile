import 'package:iamhere/common/util/app_logger.dart';
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

    AppLogger.debug('AuthSessionSync: syncing signed-in session');

    try {
      final myInfo = await _userMeService.fetchMyInfo();
      if (myInfo == null) {
        AppLogger.warning('AuthSessionSync: /api/users/my returned null');
        return false;
      }

      final effectiveIsActive =
          myInfo.isActive ?? await _tokenStorage.getIsActive() ?? true;
      AppLogger.debug(
        'AuthSessionSync: myInfo.userStatus=${myInfo.userStatus} myInfo.isActive=${myInfo.isActive} effectiveIsActive=$effectiveIsActive',
      );
      await _tokenStorage.saveAuthSnapshot(
        userStatus: myInfo.userStatus,
        isActive: effectiveIsActive,
      );
      AppLogger.debug('AuthSessionSync: snapshot saved');
      return true;
    } catch (e, st) {
      AppLogger.error('인증 세션 동기화 실패', e, st);
      return false;
    }
  }
}
