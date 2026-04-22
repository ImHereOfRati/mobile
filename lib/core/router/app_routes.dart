import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  static String termsDetail(int termDefinitionId) =>
      '/terms-detail/$termDefinitionId';

  // ── Main (ShellRoute) ─────────────────────────────────────────────
  static const String geofence = '/geofence';
  static const String geofenceEnroll = '/geofence/message';
  static const String contact = '/friend';
  static const String contactAdd = '/friend/add';
  static const String friendRequests = '/friend/requests';
  static const String friendRestrictions = '/friend/restrictions';
  static const String record = '/record';
  static const String recordNotifications = '/record/notifications';
  static const String recordFriendRequests = '/record/friend-requests';
  static const String recordSendHistory = '/record/send-history';
  static const String setting = '/setting';

  /// BottomNavigationBar 탭 순서와 일치해야 합니다.
  static const List<String> mainTabs = [geofence, contact, record, setting];

  // ── Navigation helpers ────────────────────────────────────────────
  static void goToUserPermission(BuildContext context) =>
      context.go(userPermission);
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
  static void goToRecordFriendRequests(BuildContext context) =>
      context.push(recordFriendRequests);
  static void goToRecordSendHistory(BuildContext context) =>
      context.push(recordSendHistory);
  static void goToGeofence(BuildContext context) => context.go(geofence);
  static void pushTermsDetail(BuildContext context, int termDefinitionId) =>
      context.push(termsDetail(termDefinitionId));
}
