import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FriendHeader extends StatelessWidget {
  final int count;

  const FriendHeader({required this.count, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 친구',
            style: TextStyle(
              fontFamily: 'GmarketSans',
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '메시지 보는 알람을 받을 수 있는 친구들을 관리하세요',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$count명 등록됨',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: cs.primary,
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
