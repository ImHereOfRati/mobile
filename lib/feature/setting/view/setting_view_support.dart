import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';

class SettingLabelFormatter {
  const SettingLabelFormatter._();

  static String battery(PermissionState state) {
    if (!Platform.isAndroid) return '해당 없음';
    switch (state) {
      case PermissionState.grantedAlways:
        return '제외됨';
      case PermissionState.permanentlyDenied:
        return '시스템에서 거부됨';
      case PermissionState.restricted:
        return '제한됨';
      case PermissionState.denied:
      case PermissionState.grantedWhenInUse:
        return '미적용';
      case PermissionState.serviceDisabled:
        return '서비스 상태 불량';
    }
  }

  static String permission(PermissionState state, {bool toggle = false}) {
    if (toggle) {
      return (state == PermissionState.grantedAlways ||
              state == PermissionState.grantedWhenInUse)
          ? '켜짐'
          : '꺼짐';
    }

    switch (state) {
      case PermissionState.grantedAlways:
        return '항상 허용';
      case PermissionState.grantedWhenInUse:
        return '사용 중 허용';
      default:
        return '거부됨';
    }
  }
}

class SettingActionHandler {
  const SettingActionHandler._();

  static Future<void> handlePermissionTap(
    BuildContext context,
    WidgetRef ref,
    PermissionState current,
    Future<void> Function() request,
  ) async {
    final needsOsSettings =
        current == PermissionState.grantedAlways ||
        current == PermissionState.grantedWhenInUse ||
        current == PermissionState.permanentlyDenied ||
        current == PermissionState.restricted;

    if (needsOsSettings) {
      await ph.openAppSettings();
      await ref.read(settingViewModelProvider.notifier).refreshPermissions();
      return;
    }

    await request();
  }

  static Future<void> handleBatteryOptimizationTap(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final granted = await AppRoutes.pushBatteryOptimizationGuide(context);
    ref.invalidate(batteryOptimizationStatusProvider);
    if (!context.mounted) return;

    await ref.read(settingViewModelProvider.notifier).refreshPermissions();
    if (granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('배터리 최적화 제외가 적용되었습니다.')),
      );
    }
  }

  static Future<void> openSupportPage(BuildContext context) async {
    final url = Uri.parse(
      'https://dsko.notion.site/d75b9924c10c47f0b91e4da6ee4251ec?pvs=105',
    );
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문의하기 페이지를 열 수 없습니다.')),
        );
      }
    }
  }
}
