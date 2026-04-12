import 'package:iamhere/auth/model/login_result.dart';

abstract class AuthServiceInterface {
  /// 서버에 ID 토큰을 전송하고 사용자 상태(신규/기존)를 반환합니다.
  Future<LoginResult> sendIdTokenToServer(String idToken);
}
