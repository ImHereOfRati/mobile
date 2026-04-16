import 'package:flutter/services.dart';
import 'package:iamhere/feature/auth/model/login_result.dart';
import 'package:iamhere/feature/auth/service/auth_service.dart';
import 'package:iamhere/feature/auth/view_model/auth_view_model_interface.dart';
import 'package:iamhere/integration/fcm/service/fcm_token_service.dart';
import 'package:iamhere/shared/base/result/error_analyst.dart';
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
    final result = await _doUserKakaoLogin();

    return result.when(
      success: (idToken) async =>
          Success(await _authService.sendIdTokenToServer(idToken!)),
      failure: (msg) async => Failure(msg),
    );
  }

  @override
  Future<Result<ResultMessage>> requestFCMTokenAndSendToServer() async {
    final fcmToken = await _fcmTokenService.generateAndSaveFcmToken();
    if (fcmToken == null) {
      return Failure(ResultMessage.fcmTokenGenerateFail.toString());
    }
    await _enrollFcmTokenToServer();
    return Success(ResultMessage.fcmTokenGenerateSuccess);
  }

  Future<Result<String?>> _doUserKakaoLogin() async {
    if (await isKakaoTalkInstalled()) {
      return _loginWithKakaoTalkApplication();
    }
    return _loginWithKakaoAccountOnWebPopUp();
  }

  Future<Result<String?>> _loginWithKakaoTalkApplication() async {
    try {
      final token = await UserApi.instance.loginWithKakaoTalk();
      return Success(token.idToken);
    } catch (error, trace) {
      if (error is PlatformException && error.code == 'CANCELED') {
        return Failure(
          ResultMessage.kakaoLoginCanceled.toString(),
          trace: trace,
        );
      }

      return Failure(ResultMessage.kakaoTalkLoginFail.toString(), trace: trace);
    }
  }

  Future<Result<String?>> _loginWithKakaoAccountOnWebPopUp() async {
    try {
      final token = await UserApi.instance.loginWithKakaoAccount();
      return Success(token.idToken);
    } catch (error, trace) {
      return Failure(
        ResultMessage.kakaoAccountLoginFail.toString(),
        trace: trace,
      );
    }
  }

  Future<void> _enrollFcmTokenToServer() async {
    final isSuccess = await _fcmTokenService.enrollFcmTokenToServer();
    if (!isSuccess) {
      ErrorAnalyst.log(
        ResultMessage.fcmTokenServerFail.toString(),
        StackTrace.current,
      );
    }
  }
}
