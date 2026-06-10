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
      color: isReady ? cs.primaryContainer : cs.errorContainer,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(cs, isReady),
              SizedBox(height: 10.h),
              Text(
                readiness.summaryTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isReady ? cs.onPrimaryContainer : cs.onErrorContainer,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                readiness.summaryDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (isReady ? cs.onPrimaryContainer : cs.onErrorContainer)
                      .withValues(alpha: 0.82),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Text(
                    readiness.primaryActionLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isReady ? cs.onPrimaryContainer : cs.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.chevron_right,
                    color: isReady ? cs.onPrimaryContainer : cs.onErrorContainer,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, bool isReady) {
    final bgColor = isReady ? cs.primary : cs.error;
    final fgColor = isReady ? cs.onPrimary : cs.onError;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReady ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 16.sp,
            color: fgColor,
          ),
          SizedBox(width: 6.w),
          Text(
            isReady ? '자동 전송 사용 가능' : '자동 전송 준비 필요',
            style: TextStyle(
              color: fgColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
