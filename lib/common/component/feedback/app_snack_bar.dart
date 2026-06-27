import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/common/component/theme/app_feedback_colors.dart';

class AppSnackBar {
  const AppSnackBar._();

  static OverlayEntry? _activeInfoBanner;
  static Timer? _activeInfoBannerTimer;

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
    showNotificationBanner(context, title: 'ImHere', message: message);
  }

  static void showNotificationBanner(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    if (!context.mounted) return;

    _dismissInfoBanner();

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    final theme = Theme.of(context);
    _activeInfoBanner = OverlayEntry(
      builder: (context) => _NotificationBannerOverlay(
        title: title,
        message: message,
        theme: theme,
      ),
    );
    overlay.insert(_activeInfoBanner!);

    _activeInfoBannerTimer = Timer(const Duration(seconds: 3), _dismissInfoBanner);
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

  static void _dismissInfoBanner() {
    _activeInfoBannerTimer?.cancel();
    _activeInfoBannerTimer = null;
    _activeInfoBanner?.remove();
    _activeInfoBanner = null;
  }
}

class _NotificationBannerOverlay extends StatelessWidget {
  const _NotificationBannerOverlay({
    required this.title,
    required this.message,
    required this.theme,
  });

  final String title;
  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final background = Color.lerp(primary, Colors.white, 0.12) ?? primary;
    final backgroundEnd = Color.lerp(primary, Colors.black, 0.08) ?? primary;

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Material(
              color: Colors.transparent,
              child: Container(
                key: const Key('app-notification-banner'),
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [background, backgroundEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BannerLogo(primary: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'GmarketSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'BMHANNAAir',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.96),
                              height: 1.28,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerLogo extends StatelessWidget {
  const _BannerLogo({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(7),
      child: Image.asset(
        'assets/images/app_logo.png',
        color: primary,
        colorBlendMode: BlendMode.srcIn,
        fit: BoxFit.contain,
      ),
    );
  }
}
