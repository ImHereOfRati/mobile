import 'package:dio/dio.dart';

/// 모든 API 엔드포인트 경로를 한 곳에서 관리합니다.
/// Access token 포함 여부는 [publicOptions] / [authOptions] 를 통해 결정합니다.
///
/// 참고: https://fortuneki.site/swagger-ui/index.html
class ApiConfig {
  const ApiConfig._();

  // ── Auth ─────────────────────────────────────────────────────────
  /// POST — 카카오 OAuth 로그인 (신규/기존 유저 공통)
  static const String authLoginPath = '/api/user/auth/login';

  /// POST — JWT 액세스 토큰 재발급
  static const String authReissuePath = '/api/user/auth/reissue';

  // ── User ─────────────────────────────────────────────────────────
  /// GET — 내 정보 조회 (이메일, 닉네임)
  static const String userMePath = '/api/user/info/me';

  /// POST — 닉네임 변경
  static const String userNicknamePath = '/api/user/info/nickname';

  /// GET — 닉네임으로 유저 검색 (?nickname=...)
  static const String userSearchPath = '/api/user/info/tester';

  // ── Terms ─────────────────────────────────────────────────────────
  /// GET — 약관 목록 조회 (페이지네이션)
  static const String termsListPath = '/api/user/terms';

  /// POST — 전체 약관 일괄 동의 → 응답으로 accessToken, refreshToken 발급
  static const String termsConsentPath = '/api/user/terms/consent';

  /// GET — 약관 버전 상세 조회
  static String termsVersionPath(int termDefinitionId) =>
      '/api/user/terms/version/$termDefinitionId';

  // ── Notification (FCM) ────────────────────────────────────────────
  /// POST — FCM 토큰 서버 등록
  static const String fcmEnrollPath = '/api/v1/notification/enroll';

  // ── Options helpers ───────────────────────────────────────────────
  /// 인증 토큰을 포함하지 않는 요청 (로그인, 토큰 재발급, 약관 목록 등).
  static Options get publicOptions =>
      Options(extra: const {'requiresAuth': false});

  /// 인증 토큰을 포함하는 요청 (기본값 — 명시적으로 전달할 때 사용).
  static Options get authOptions =>
      Options(extra: const {'requiresAuth': true});
}
