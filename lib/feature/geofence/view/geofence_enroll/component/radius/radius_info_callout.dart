import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class RadiusInfoCallout extends StatelessWidget {
  final String message;

  const RadiusInfoCallout({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border(
          left: BorderSide(color: cs.primary, width: 3.w),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Text(
        message,
        style: AppTextStyles.hannaAirRegular(
          13,
          cs.onSurface.withValues(alpha: 0.65),
        ).copyWith(height: 1.4),
      ),
    );
  }
}
