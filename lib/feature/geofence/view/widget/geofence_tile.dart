import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GeofenceTile extends StatelessWidget {
  final bool isToggleOn;
  final ValueChanged<bool> onToggleChanged;
  final String homeName;
  final String address;
  final int memberCount;
  final VoidCallback? onLongPress;

  const GeofenceTile({
    super.key,
    required this.isToggleOn,
    required this.onToggleChanged,
    required this.homeName,
    required this.address,
    required this.memberCount,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: isToggleOn
              ? cs.primary.withValues(alpha: 0.08)
              : cs.surface,
          borderRadius: BorderRadius.circular(8.r),
        ),
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Row(
          children: [
            // 활성 상태 인디케이터
            Container(
              width: 4.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: isToggleOn
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 14.w),

            // 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    homeName,
                    style: tt.headlineSmall?.copyWith(
                      fontSize: 19.sp,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14.r,
                        color: tt.bodyMedium?.color,
                      ),
                      SizedBox(width: 3.w),
                      Flexible(
                        child: Text(
                          address,
                          style: tt.bodyMedium?.copyWith(fontSize: 13.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.people_outline,
                        size: 14.r,
                        color: tt.bodyMedium?.color,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        '$memberCount명',
                        style: tt.bodyMedium?.copyWith(fontSize: 13.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // 토글
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isToggleOn,
                onChanged: onToggleChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: cs.primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: cs.onSurface.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
