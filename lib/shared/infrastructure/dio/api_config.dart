import 'package:dio/dio.dart';

/// ImHere API 엔드포인트 및 요청 옵션 설정 클래스
///
/// 작성일: 2026-04-13
class ApiConfig {
  const ApiConfig._();

  // ── Auth & Identity ─────────────────────────────────────────────
  /// POST — 카카오 OAuth 로그인 (신규/기존 유저 공통)
  static const String authLoginPath = '/api/user/auth/login';

  /// POST — JWT 액세스 토큰 재발급
  static const String authReissuePath = '/api/user/auth/reissue';

  // ── User Information ────────────────────────────────────────────
  /// GET — 내 정보 조회 (이메일, 닉네임)
  static const String userMePath = '/api/user/info/me';

  /// POST — 닉네임 변경
  static const String userNicknamePath = '/api/user/info/nickname';

  /// GET — 닉네임으로 유저 검색 (Query Param: nickname)
  static const String userSearchPath = '/api/user/info/tester';

  // ── Terms ───────────────────────────────────────────────────────
  /// GET — 약관 종류 목록 조회 (페이지네이션)
  static const String termsListPath = '/api/user/terms';

  /// POST — 전체 약관 일괄 동의 (응답으로 신규 토큰 발급)
  static const String termsConsentPath = '/api/user/terms/consent';

  /// GET — 특정 약관의 활성화된 버전 상세 조회
  static String termsVersionPath(String termsDefinitionId) =>
      '/api/user/terms/version/$termsDefinitionId';

  // ── Notification (FCM) ──────────────────────────────────────────
  /// POST — FCM 토큰 서버 등록 (디바이스 정보 포함)
  static const String fcmEnrollPath = '/api/notification/fcmToken';

  /// POST — 일반적인 알림 발송 (친구 요청 등)
  static const String fcmNotificationPath = '/api/notification/fcm/send';

  /// POST — 목적지 도착 알림 발송 (특정 상대방 타겟)
  static const String fcmArrivalPath = '/api/notification/fcm/arrival';

  /// POST — 알림 정상 발송 결과 본인 통보용
  static const String fcmDeliveryResultPath =
      '/api/notification/fcm/delivery-result';

  /// POST — 위치 정보 수신 대상자 선정 알림
  static const String fcmLocationTargetPath = '/api/notification/fcm/location';

  // ── Notification (SMS) ──────────────────────────────────────────
  /// POST — 단일 SMS 발송 (앱 미설치 유저용)
  static const String smsSendSinglePath = '/api/notification/sms/send';

  /// POST — 다중 SMS 발송
  static const String smsSendMultiPath = '/api/notification/sms/send/multi';

  // ── Admin (CS & Management) ─────────────────────────────────────
  /// DELETE — 두 유저 간의 친구 관계 강제 삭제
  static const String adminFriendClearPath = '/api/admin/friends';

  /// DELETE — 특정 친구 요청 강제 삭제
  static const String adminFriendRequestClearPath =
      '/api/admin/friends/requests';

  /// POST — 새로운 약관 종류 생성
  static const String adminTermsDefinitionPath = '/api/admin/terms/definition';

  /// POST — 약관 버전 신규 등록
  static const String adminTermsVersionPath = '/api/admin/terms/version';

  /// POST — 특정 유저 서비스 이용 차단
  static String adminUserBlockPath(String email) =>
      '/api/admin/users/$email/block';

  /// DELETE — 유저 차단 해제
  static String adminUserUnblockPath(String email) =>
      '/api/admin/users/$email/block';

  /// DELETE — 유저 강제 로그아웃 (토큰 무효화)
  static String adminUserForceLogoutPath(String email) =>
      '/api/admin/users/$email/token';

  // ── Options Helpers ─────────────────────────────────────────────
  /// 인증 토큰을 포함하지 않는 요청 (로그인, 재발급 등)
  static Options get publicOptions =>
      Options(extra: const {'requiresAuth': false});

  /// 인증 토큰을 필수로 포함하는 요청 (기본값)
  static Options get authOptions =>
      Options(extra: const {'requiresAuth': true});
}
