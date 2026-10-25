import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/core/result/result_message.dart';
import 'package:iamhere/core/result/error_analyst.dart';
import 'package:iamhere/feature/auth/model/service/account/token_storage_service.dart';
import 'package:iamhere/integration/fcm/service/fcm_token_service.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthFcmRegistrationService {
  AuthFcmRegistrationService(this._fcmTokenService, this._tokenStorage);

  final FcmTokenService _fcmTokenService;
  final TokenStorageService _tokenStorage;

  Future<void> registerForActiveAccount() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      if (await _tokenStorage.getPendingAuth()) return;
      final status = (await _tokenStorage.getUserStatus())?.toUpperCase();
      final isActive = await _tokenStorage.getIsActive();
      if (status == 'PENDING' || status == 'INACTIVE' || isActive == false) {
        return;
      }
      if (status != 'ACTIVE' && isActive != true) return;
      await requestAndEnroll();
    } catch (error, stackTrace) {
      ErrorAnalyst.log(error.toString(), stackTrace);
    }
  }

  Future<Result<ResultMessage>> requestAndEnroll() async {
    final token = await _fcmTokenService.syncTokenAndEnroll();
    if (token == null) {
      return Failure(ResultMessage.fcmTokenGenerateFail.toString());
    }
    return Success(ResultMessage.fcmTokenGenerateSuccess);
  }
}
