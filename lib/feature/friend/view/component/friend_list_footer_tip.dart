import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FriendListFooterTip extends StatelessWidget {
  const FriendListFooterTip({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Text(
        '친구가 앱을 삭제하면 위치 알람 전송이 실패할 수 있습니다.',
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 12.sp,
          color: cs.onSurface.withValues(alpha: 0.4),
          height: 1.4,
        ),
      ),
    );
  }
}
