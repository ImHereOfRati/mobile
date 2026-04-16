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

  /// GET — 이메일 또는 닉네임으로 유저 검색 (PathVariable: keyword)
  static String userSearchPath(String keyword) => '/api/user/info/$keyword';

  // ── Terms ───────────────────────────────────────────────────────
  /// GET — 약관 종류 목록 조회 (페이지네이션)
  static const String termsListPath = '/api/user/terms';

  /// POST — 전체 약관 일괄 동의 (응답으로 신규 토큰 발급)
  static const String allTermsConsentPath = '/api/user/terms/consent';

  static String termConsentPath(String termDefinitionId) =>
      '/api/user/terms/consent/$termDefinitionId';

  /// GET — 특정 약관의 활성화된 버전 상세 조회
  static String termsVersionPath(String termsDefinitionId) =>
      '/api/user/terms/version/$termsDefinitionId';

  // ── Friend Relationship ─────────────────────────────────────────
  /// GET — 내 친구 목록 조회
  static const String friendListPath = '/api/user/friends';

  /// POST — 친구 별명 변경
  static const String friendAliasPath = '/api/user/friends/alias';

  /// POST — 친구 차단
  static String friendBlockPath(String friendRelationshipId) =>
      '/api/user/friends/block/$friendRelationshipId';

  /// DELETE — 친구 관계 삭제
  static String friendDeletePath(String friendRelationshipId) =>
      '/api/user/friends/$friendRelationshipId';

  // ── Friend Request ─────────────────────────────────────────────
  /// POST — 친구 요청 보내기 / GET — 받은 친구 요청 목록 조회
  static const String friendRequestPath = '/api/user/friends/request';

  /// GET — 친구 요청 상세 조회
  static String friendRequestDetailPath(int requestId) =>
      '/api/user/friends/request/$requestId';

  /// POST — 친구 요청 수락
  static String friendRequestAcceptPath(int requestId) =>
      '/api/user/friends/request/accept/$requestId';

  /// POST — 친구 요청 거절
  static String friendRequestRejectPath(int requestId) =>
      '/api/user/friends/request/reject/$requestId';

  // ── Friend Restriction ─────────────────────────────────────────
  /// GET — 제한(차단/거절) 목록 조회
  static const String friendRestrictionPath = '/api/user/friends/restriction';

  /// DELETE — 제한 해제 (차단 해제)
  static String friendRestrictionDeletePath(int friendRestrictionId) =>
      '/api/user/friends/restriction/$friendRestrictionId';

  // ── Notification (FCM) ──────────────────────────────────────────
  /// POST — FCM 토큰 서버 등록 (디바이스 정보 포함)
  static const String fcmEnrollPath = '/api/notification/fcmToken';

  /// POST — 일반적인 알림 발송 (친구 요청 등)
  static const String fcmNotificationPath = '/api/notification/fcm/send';

  /// POST — 목적지 도착 알림 발송 (특정 상대방 타겟)
  static const String fcmArrivalPath = '/api/notification/fcm/arrival';

  /// POST - 문자 메시지 발송(단건)
  static const String smsArrivalPath = '/api/notification/sms/send';

  /// POST - 문자 메시지 발송(여러 건)
  static const String smsMultipleArrivalPath =
      '/api/notification/sms/send/multi';

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

  // ── Options Helpers ─────────────────────────────────────────────
  /// 인증 토큰을 포함하지 않는 요청 (로그인, 재발급 등)
  static Options get publicOptions =>
      Options(extra: const {'requiresAuth': false});

  /// 인증 토큰을 필수로 포함하는 요청 (기본값)
  static Options get authOptions =>
      Options(extra: const {'requiresAuth': true});
}
