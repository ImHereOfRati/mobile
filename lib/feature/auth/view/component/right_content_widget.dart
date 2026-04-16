import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget rightContentWidget({
  required BuildContext context,
  required String right,
}) {
  int length = right.length;
  int maxLength = 6;
  if (length > maxLength) {
    length = maxLength;
  }

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 5.w),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(35.0),
      child: Container(
        width: 18.w * length,
        height: 30.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(35.0),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                right,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
