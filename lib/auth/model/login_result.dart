/// 카카오 로그인 후 사용자 상태를 나타내는 enum
enum LoginResult {
  /// HTTP 201 - 신규 사용자 (약관 동의 필요)
  newUser,

  /// HTTP 200 - 기존 사용자 (직접 메인 화면으로)
  existingUser,
}
