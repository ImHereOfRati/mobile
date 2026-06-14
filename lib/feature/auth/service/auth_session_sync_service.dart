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
    if (accessToken == null || accessToken.isEmpty) return false;

    try {
      final myInfo = await _userMeService.fetchMyInfo();
      if (myInfo == null) return false;

      final effectiveIsActive =
          myInfo.isActive ?? await _tokenStorage.getIsActive() ?? true;
      await _tokenStorage.saveAuthSnapshot(
        userStatus: myInfo.userStatus,
        isActive: effectiveIsActive,
      );
      return true;
    } catch (e, st) {
      AppLogger.error('인증 세션 동기화 실패', e, st);
      return false;
    }
  }
}
