import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthInfoCard extends StatelessWidget {
  final String title;
  final List<(IconData, String, String)> items;

  const AuthInfoCard({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              color: cs.onSurface.withValues(alpha: 0.5),
              letterSpacing: -0.12,
            ),
          ),
          SizedBox(height: 12.h),
          ...items.map((item) => AuthInfoRow(item: item)),
        ],
      ),
    );
  }
}

class AuthInfoRow extends StatelessWidget {
  final (IconData, String, String) item;

  const AuthInfoRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(item.$1, size: 18.r, color: cs.primary),
          SizedBox(width: 10.w),
          Text(
            item.$2,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.224,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              item.$3,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 13.sp,
                color: cs.onSurface.withValues(alpha: 0.5),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
