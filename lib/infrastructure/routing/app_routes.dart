import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/record/repository/notification_entity.dart';
import 'package:iamhere/feature/record/repository/geofence_record_entity.dart';

/// 앱의 모든 경로를 한 곳에서 관리합니다.
///
/// 경로 변경 시 이 파일만 수정하면 됩니다.
/// 내비게이션은 [go], [push] 헬퍼 메서드를 사용하세요.
class AppRoutes {
  const AppRoutes._();

  // ── Onboarding ────────────────────────────────────────────────────
  static const String userPermission = '/user-permission';
  static const String locationPermissionGuide = '/location-permission-guide';
  static const String batteryOptimizationGuide = '/battery-optimization-guide';
  static const String auth = '/auth';
  static const String termsConsent = '/terms-consent';

  // ── Main (ShellRoute) ─────────────────────────────────────────────
  static const String geofence = '/geofence';
  static const String geofenceEnroll = '/geofence/message';
  static const String contact = '/friend';
  static const String contactAdd = '/friend/add';
  static const String friendRequests = '/friend/requests';
  static const String friendRestrictions = '/friend/restrictions';
  static const String record = '/record';
  static const String recordNotifications = '/record/notifications';
  static const String recordNotificationDetail = '/record/notifications/detail';
  static const String recordFriendRequests = '/record/friend-requests';
  static const String recordSendHistory = '/record/send-history';
  static const String recordSendHistoryDetail = '/record/send-history/detail';
  static const String setting = '/setting';
  static const String termsDetail = '/terms-detail/:termId';

  /// BottomNavigationBar 탭 순서와 일치해야 합니다.
  static const List<String> mainTabs = [geofence, contact, record, setting];

  // ── Navigation helpers ────────────────────────────────────────────
  static Future<void> pushUserPermission(BuildContext context) =>
      context.push(userPermission);
  static Future<bool> pushLocationPermissionGuide(BuildContext context) async {
    final result = await context.push<bool>(locationPermissionGuide);
    return result ?? false;
  }

  static Future<bool> pushBatteryOptimizationGuide(BuildContext context) async {
    final result = await context.push<bool>(batteryOptimizationGuide);
    return result ?? false;
  }

  static void goToAuth(BuildContext context) => context.go(auth);
  static void goToTermsConsent(BuildContext context) =>
      context.go(termsConsent);
  static void goToContactAdd(BuildContext context) => context.push(contactAdd);
  static void goToFriendRequests(BuildContext context) =>
      context.push(friendRequests);
  static void goToFriendRestrictions(BuildContext context) =>
      context.push(friendRestrictions);
  static void goToRecordNotifications(BuildContext context) =>
      context.push(recordNotifications);
  static void goToNotificationDetail(
    BuildContext context,
    NotificationEntity notification,
  ) =>
      context.push(recordNotificationDetail, extra: notification);
  static void goToRecordFriendRequests(BuildContext context) =>
      context.push(recordFriendRequests);
  static void goToRecordSendHistory(BuildContext context) =>
      context.push(recordSendHistory);
  static void goToSendHistoryDetail(
    BuildContext context,
    GeofenceRecordEntity record,
  ) =>
      context.push(recordSendHistoryDetail, extra: record);
  static void goToGeofence(BuildContext context) => context.go(geofence);
  static void goToTermsDetail(BuildContext context, int termId) =>
      context.push('/terms-detail/$termId');
}
