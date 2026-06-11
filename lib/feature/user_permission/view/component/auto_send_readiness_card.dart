import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';

class AutoSendReadinessCard extends StatelessWidget {
  final AutoSendReadiness readiness;
  final VoidCallback onTap;

  const AutoSendReadinessCard({
    super.key,
    required this.readiness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isReady = readiness.isReady;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(cs, isReady),
              SizedBox(height: 8.h),
              Text(
                readiness.summaryDescription,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.76),
                  fontSize: 14.sp,
                ),
              ),
              Divider(
                height: 24.h,
                color: cs.outlineVariant,
              ),
              _buildActionRow(cs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(ColorScheme cs, bool isReady) {
    return Row(
      children: [
        _buildIconBlock(cs, isReady),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBadge(cs, isReady),
              SizedBox(height: 4.h),
              Text(
                readiness.summaryTitle,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconBlock(ColorScheme cs, bool isReady) {
    final bgColor = isReady ? cs.primaryContainer : cs.errorContainer;
    final iconColor = isReady ? cs.primary : cs.error;

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isReady ? Icons.check_circle : Icons.warning_amber_rounded,
          color: iconColor,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ColorScheme cs, bool isReady) {
    final bgColor = isReady ? cs.primary : cs.error;
    final fgColor = cs.onPrimary;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        isReady ? '자동 전송 사용 가능' : '자동 전송 준비 필요',
        style: TextStyle(
          color: fgColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionRow(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          readiness.primaryActionLabel,
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: cs.primary,
        ),
      ],
    );
  }
}
