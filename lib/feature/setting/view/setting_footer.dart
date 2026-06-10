import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingFooter extends StatelessWidget {
  const SettingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Text(
            'Imhere © 2025',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.12,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '도착 알림 자동 연락 서비스',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.12,
            ),
          ),
        ],
      ),
    );
  }
}
