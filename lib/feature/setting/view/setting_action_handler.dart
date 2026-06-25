import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/common/component/dialog/app_confirm_dialog.dart';
import 'package:iamhere/common/component/feedback/app_snack_bar.dart';
import 'package:iamhere/common/util/app_logger.dart';
import 'package:iamhere/feature/auth/service/auth_state_provider.dart';
import 'package:iamhere/feature/auth/service/token_storage_service.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/infrastructure/di/di_setup.dart';
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

  static Future<void> handleWithdrawAccountTap(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmDialog(
        title: '회원 탈퇴',
        content: '탈퇴하면 계정과 연결된 정보가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.',
        confirmText: '탈퇴',
        confirmTextColor: cs.error,
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await _withdrawAccount();
    if (!context.mounted) return;

    if (!success) {
      AppSnackBar.showError(context, '회원 탈퇴에 실패했습니다. 다시 시도해주세요.');
      return;
    }

    await _clearLocalAuthState();
    if (!context.mounted) return;

    ref.invalidate(authStateProvider);
    context.go(AppRoutes.auth);

    if (!context.mounted) return;
    AppSnackBar.showSuccess(context, '회원 탈퇴가 완료되었습니다.');
  }

  static Future<bool> _withdrawAccount() async {
    try {
      final dio = getIt<Dio>();
      final response = await dio.delete(
        '/api/users/my/withdrawal',
        options: Options(extra: const {'requiresAuthentication': true}),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e, st) {
      AppLogger.error('회원 탈퇴 API 호출 실패', e, st);
      return false;
    } catch (e, st) {
      AppLogger.error('회원 탈퇴 처리 중 알 수 없는 오류', e, st);
      return false;
    }
  }

  static Future<void> _clearLocalAuthState() async {
    final tokenStorage = getIt<TokenStorageService>();
    await tokenStorage.deleteAllTokens();
  }
}
