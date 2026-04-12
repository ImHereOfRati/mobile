import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:iamhere/auth/model/login_result.dart';
import 'package:iamhere/auth/service/auth_service.dart';
import 'package:iamhere/auth/view_model/auth_view_model_interface.dart';
import 'package:iamhere/fcm/service/fcm_token_service.dart';
import 'package:iamhere/shared/base/result/result.dart';
import 'package:iamhere/shared/base/result/result_message.dart';
import 'package:injectable/injectable.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

@injectable
class AuthViewModel implements AuthViewModelInterface {
  final AuthService _authService;
  final FcmTokenService _fcmTokenService;

  AuthViewModel(this._authService, this._fcmTokenService);

  @override
  Future<Result<LoginResult>> handleKakaoLogin() async {
    String? idToken;
    var result = await _doUserKakaoLogin();
    switch (result) {
      case Success(data: var d):
        idToken = d;
        final isNewUser = await _authService.sendIdTokenToServer(idToken!);
        final loginResult = isNewUser
            ? LoginResult.newUser
            : LoginResult.existingUser;
        return Success(loginResult);
      case Failure():
        return Failure(ResultMessage.kakaoAuthFail.toString());
    }
  }

  @override
  Future<Result<ResultMessage>> requestFCMTokenAndSendToServer() async {
    // FCM 토큰 발급 및 로컬 저장
    final fcmToken = await _fcmTokenService.generateAndSaveFcmToken();

    if (fcmToken == null) {
      return Failure(ResultMessage.fcmTokenGenerateFail.toString());
    }

    await _enrollFcmTokenToServer(_fcmTokenService);
    return Success(ResultMessage.fcmTokenGenerateSuccess);
  }

  /// 카카오 로그인 담당 로직
  Future<Result<String?>> _doUserKakaoLogin() async {
    if (await isKakaoTalkInstalled()) {
      return await _loginWithKakaoTalkApplication();
    }

    return await _loginWithKakaoAccountOnWebPopUp();
  }

  Future<Result<String?>> _loginWithKakaoTalkApplication() async {
    try {
      OAuthToken oAuthToken = await UserApi.instance.loginWithKakaoTalk();
      return Success(oAuthToken.idToken);
    } catch (error) {
      String msg = '카카오톡 어플 로그인 실패';
      if (error is PlatformException && error.code == 'CANCELED') {
        msg = '의도적인 취소로 인한 실패';
      }
      return Failure(msg);
    }
  }

  Future<Result<String?>> _loginWithKakaoAccountOnWebPopUp() async {
    try {
      OAuthToken oAuthToken = await UserApi.instance.loginWithKakaoAccount();
      return Success(oAuthToken.idToken);
    } catch (error) {
      return Failure('카카오 계정으로 로그인 실패');
    }
  }

  /// FCM 담당 로직
  Future<void> _enrollFcmTokenToServer(FcmTokenService fcmTokenService) async {
    final enrollSuccess = await fcmTokenService.enrollFcmTokenToServer();

    if (enrollSuccess) {
      debugPrint('FCM token workflow completed successfully');
    } else {
      debugPrint('FCM token enrollment to server failed');
    }
  }
}
