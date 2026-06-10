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
    final (label, background, foreground) = switch ((isToggleOn, isAutoSendReady)) {
      (false, _) => ('자동 전송 꺼짐', cs.surfaceContainerHighest, cs.onSurfaceVariant),
      (true, true) => ('자동 전송 준비 완료', cs.primary.withValues(alpha: 0.12), cs.primary),
      (true, false) => ('준비 필요', cs.errorContainer, cs.error),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(label, style: AppTextStyles.hannaAirBold(11, foreground)),
    );
  }
}
