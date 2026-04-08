abstract class AuthServiceInterface {
  /// 서버에 ID 토큰을 전송하고 사용자 상태(신규/기존)를 반환합니다.
  ///
  /// Returns:
  ///   true: 신규 사용자 (HTTP 201)
  ///   false: 기존 사용자 (HTTP 200)
  Future<bool> sendIdTokenToServer(String idToken);
}
