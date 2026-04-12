import 'package:flutter/material.dart';

/// 앱 전반에서 일관된 SnackBar 스타일을 제공합니다.
/// Apple Design System 색상 토큰을 따릅니다.
class AppSnackBar {
  const AppSnackBar._();

  /// 오류 메시지 (빨간 계열)
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFFFF3B30),
      icon: Icons.error_outline_rounded,
    );
  }

  /// 성공 메시지 (초록 계열)
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF34C759),
      icon: Icons.check_circle_outline_rounded,
    );
  }

  /// 정보 메시지 (파란 계열)
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF0071E3),
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 14,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
