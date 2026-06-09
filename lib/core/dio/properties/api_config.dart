// import 'package:dio/dio.dart';
//
// class ApiConfig {
//   const ApiConfig._();
//
//   static const String authLoginPath = '/api/auth/login';
//   static const String authRegistrationPath = '/api/auth/registration';
//   static const String authReissuePath = '/api/auth/refresh';
//
//   static const String userMePath = '/api/users/my';
//   static const String userNicknamePath = '/api/users/my';
//
//   /// TODO: keyword를 실제 쿼리 파라미터로 반영하는 방식으로 정리
//   static String userSearchPath(String _keyword) => '/api/users';
//
//   static const String termsListPath = '/api/terms';
//   static const String allTermsConsentPath = '/api/auth/activation';
//
//   /// TODO: termDefinitionId를 실제 경로/쿼리로 반영하도록 수정
//   static String termConsentPath(String _termDefinitionId) =>
//       '/api/auth/activation';
//
//   /// TODO: termsDefinitionId를 실제 경로/쿼리로 반영하도록 수정
//   static String termsVersionPath(String _termsDefinitionId) => '/api/terms';
//
//   static const String friendListPath = '/api/friendships';
//   static String friendAliasPath(String friendRelationshipId) =>
//       '/api/friendships/$friendRelationshipId/alias';
//   static String friendBlockPath(String friendRelationshipId) =>
//       '/api/friendships/$friendRelationshipId/block';
//   static String friendDeletePath(String friendRelationshipId) =>
//       '/api/friendships/$friendRelationshipId';
//
//   static const String friendRequestPath = '/api/friends/requests';
//   static String friendRequestDetailPath(int requestId) =>
//       '/api/friends/requests/$requestId';
//   static String friendRequestAcceptPath(int requestId) =>
//       '/api/friends/requests/$requestId/accept';
//   static String friendRequestRejectPath(int requestId) =>
//       '/api/friends/requests/$requestId/reject';
//
//   static const String friendRestrictionPath = '/api/friends/restrictions';
//   static String friendRestrictionDeletePath(String friendRestrictionId) =>
//       '/api/friends/restrictions/$friendRestrictionId';
//
//   static const String fcmEnrollPath = '/api/fcm-tokens';
//   static const String fcmNotificationPath = '/api/notifications';
//   static const String fcmArrivalPath = '/api/notifications';
//   static const String smsArrivalPath = '/api/notifications';
//   static const String smsMultipleArrivalPath = '/api/notifications/batch';
//   static const String fcmDeliveryResultPath = '/api/notifications';
//   static const String fcmLocationTargetPath = '/api/notifications';
//
//   static const String smsSendSinglePath = '/api/notifications';
//   static const String smsSendMultiPath = '/api/notifications/batch';
//
//   static Options get publicOptions =>
//       Options(extra: const {'requiresAuth': false});
//
//   static Options get authOptions =>
//       Options(extra: const {'requiresAuth': true});
// }
