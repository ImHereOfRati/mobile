import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('배터리 최적화 제외가 적용되었습니다.')));
    }
  }

  static Future<void> openSupportPage(BuildContext context) async {
    final url = Uri.parse(
      'https://dsko.notion.site/37c2776ec1898041b254ee2870657dcc?pvs=105',
    );
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('문의하기 페이지를 열 수 없습니다.')));
      }
    }
  }
}
