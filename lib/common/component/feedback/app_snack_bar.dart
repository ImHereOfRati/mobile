import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/common/component/theme/app_feedback_colors.dart';

class AppSnackBar {
  const AppSnackBar._();

  static void showError(BuildContext context, String message) {
    final theme = Theme.of(context);
    _show(
      context,
      message: message,
      backgroundColor: theme.colorScheme.error,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    final theme = Theme.of(context);
    _show(
      context,
      message: message,
      backgroundColor:
          theme.extension<AppFeedbackColors>()?.success ??
          theme.colorScheme.primary,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    final theme = Theme.of(context);
    _show(
      context,
      message: message,
      backgroundColor: theme.colorScheme.primary,
      icon: Icons.info_outline_rounded,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (!context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: _buildSnackBarContent(icon, message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Row _buildSnackBarContent(IconData icon, String message) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18.r),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(message, style: AppTextStyles.mediumInfo(Colors.white)),
        ),
      ],
    );
  }
}
