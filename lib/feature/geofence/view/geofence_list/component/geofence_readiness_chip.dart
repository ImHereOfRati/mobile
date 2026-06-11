import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

/// 알림 카드의 자동 전송 준비 상태 칩.
/// 준비 완료 / 준비 필요 / 자동 전송 꺼짐 세 가지 상태를 표현한다.
class GeofenceReadinessChip extends StatelessWidget {
  final bool isToggleOn;
  final bool isAutoSendReady;

  const GeofenceReadinessChip({
    super.key,
    required this.isToggleOn,
    required this.isAutoSendReady,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, background, foreground, iconData) = switch ((isToggleOn, isAutoSendReady)) {
      (false, _) => (
          '자동 전송 꺼짐',
          cs.onSurface.withValues(alpha: 0.06),
          cs.onSurface.withValues(alpha: 0.45),
          Icons.power_settings_new_rounded,
        ),
      (true, true) => (
          '자동 전송 준비 완료',
          cs.primary.withValues(alpha: 0.08),
          cs.primary,
          Icons.check_circle_rounded,
        ),
      (true, false) => (
          '준비 필요',
          cs.error.withValues(alpha: 0.08),
          cs.error,
          Icons.warning_rounded,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 12.r,
            color: foreground,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.hannaAirBold(11, foreground),
          ),
        ],
      ),
    );
  }
}
