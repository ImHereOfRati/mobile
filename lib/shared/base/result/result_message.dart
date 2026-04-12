enum ResultMessage {
  // ── 카카오 로그인 ──────────────────────────────────────────────────
  kakaoAuthSuccess('카카오 로그인 성공'),
  kakaoAuthFail('카카오 로그인에 실패했습니다'),

  // ── FCM 토큰 ───────────────────────────────────────────────────────
  fcmTokenGenerateSuccess('알림 설정이 완료되었습니다'),
  fcmTokenGenerateFail('알림 설정에 실패했습니다. 다시 시도해 주세요'),
  fcmTokenServerSuccess('알림 토큰이 서버에 등록되었습니다'),
  fcmTokenServerFail('알림 토큰 등록에 실패했습니다'),

  // ── 약관 동의 ──────────────────────────────────────────────────────
  termsConsentSuccess('약관 동의가 완료되었습니다'),
  termsConsentFail('약관 동의 처리 중 오류가 발생했습니다. 다시 시도해 주세요'),
  termsLoadFail('약관 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요'),

  // ── 사용자 정보 ────────────────────────────────────────────────────
  userInfoLoadFail('사용자 정보를 불러오지 못했습니다'),
  nicknameChangedSuccess('닉네임이 변경되었습니다'),
  nicknameChangeFail('닉네임 변경에 실패했습니다. 다시 시도해 주세요'),
  userSearchFail('사용자 검색에 실패했습니다'),

  // ── 네트워크 / 서버 ────────────────────────────────────────────────
  dioException('서버와 통신 중 오류가 발생했습니다. 네트워크 상태를 확인해 주세요'),
  serverError('서버 오류가 발생했습니다. 잠시 후 다시 시도해 주세요'),
  unauthorizedError('인증이 만료되었습니다. 다시 로그인해 주세요'),

  // ── 알 수 없는 오류 ────────────────────────────────────────────────
  unknownError('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해 주세요');

  const ResultMessage(this.message);
  final String message;

  @override
  String toString() => message;
}
