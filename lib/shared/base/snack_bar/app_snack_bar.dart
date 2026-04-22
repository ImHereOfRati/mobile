import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class AppSnackBar {
  const AppSnackBar._();

  static const Color errorRed = Color(0xFFFF3B30);
  static const Color successGreen = Color(0xFF34C759);
  static const Color infoBlue = Color(0xFF0071E3);

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: errorRed,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: successGreen,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: infoBlue,
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
