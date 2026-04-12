enum ResultMessage {
  // 카카오 로그인
  kakaoAuthSuccess('카카오 로그인 성공'),
  kakaoAuthFail('카카오 로그인 실패'),

  // FCM 토큰 생성
  fcmTokenGenerateSuccess('FCM 토큰 생성 성공'),
  fcmTokenGenerateFail('FCM 토큰 생성에 실패했습니다'),

  // FCM 토큰 서버 저장
  fcmTokenServerSuccess('FCM 토큰 전송 완료'),
  fcmTokenServerFail('FCM 토큰 전송 실패'),

  // DIO 에러
  dioException("서버와 통신 중 오류가 발생하였습니다"),

  // 알 수 없는 에러
  unknownError('알 수 없는 오류가 발생하였습니다.');

  const ResultMessage(this.message);
  final String message;
}
