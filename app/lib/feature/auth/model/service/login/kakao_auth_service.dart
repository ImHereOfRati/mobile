import 'package:flutter/services.dart';
import 'package:iamhere/core/result/result.dart';
import 'package:iamhere/core/result/result_message.dart';
import 'package:iamhere/feature/auth/model/service/login/abstract_oauth_service.dart';
import 'package:iamhere/feature/auth/model/type/oauth_provider.dart';
import 'package:injectable/injectable.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

@injectable
class KakaoAuthService extends OAuthAuthService {
  @override
  OauthProvider get provider => OauthProvider.kakao;

  @override
  Future<Result<String?>> login({required String nonce}) async {
    if (await isKakaoTalkInstalled()) {
      return _loginWithKakaoTalk(nonce);
    }
    return _loginWithKakaoAccount(nonce);
  }

  Future<Result<String?>> _loginWithKakaoTalk(String nonce) async {
    try {
      final token = await UserApi.instance.loginWithKakaoTalk(nonce: nonce);
      return Success(token.idToken);
    } catch (error, stackTrace) {
      if (error is PlatformException && error.code == 'CANCELED') {
        return Failure(
          ResultMessage.kakaoLoginCanceled.toString(),
          trace: stackTrace,
        );
      }
      return Failure(
        ResultMessage.kakaoTalkLoginFail.toString(),
        trace: stackTrace,
      );
    }
  }

  Future<Result<String?>> _loginWithKakaoAccount(String nonce) async {
    try {
      final token = await UserApi.instance.loginWithKakaoAccount(nonce: nonce);
      return Success(token.idToken);
    } catch (error, stackTrace) {
      return Failure(
        ResultMessage.kakaoAccountLoginFail.toString(),
        trace: stackTrace,
      );
    }
  }
}
