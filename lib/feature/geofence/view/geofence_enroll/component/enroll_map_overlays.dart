import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String _locationSelected = '위치 선택됨';
const String _openMapSelect = '지도에서 위치 선택하기';

class EnrollMapSelectedBadge extends StatelessWidget {
  const EnrollMapSelectedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 12.h,
      left: 12.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 14.r, color: cs.onPrimary),
            SizedBox(width: 4.w),
            Text(
              _locationSelected,
              style: AppTextStyles.hannaAirBold(12, cs.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class EnrollMapFullscreenButton extends StatelessWidget {
  final VoidCallback onTap;
  const EnrollMapFullscreenButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 12.h,
      right: 12.w,
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20.r),
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fullscreen, size: 16.r, color: cs.primary),
                SizedBox(width: 4.w),
                Text(
                  _openMapSelect,
                  style: AppTextStyles.hannaAirBold(12, cs.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
