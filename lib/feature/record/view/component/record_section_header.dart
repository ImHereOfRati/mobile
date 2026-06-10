import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecordSectionHeader extends StatelessWidget {
  final String title;
  final int unreadCount;
  final VoidCallback? onViewAll;

  const RecordSectionHeader({
    super.key,
    required this.title,
    required this.unreadCount,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'GmarketSans',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  '전체 보기',
                  style: TextStyle(
                    fontFamily: 'BMHANNAAir',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            unreadCount > 0 ? '$unreadCount개 읽지 않음' : '읽지 않은 항목 없음',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 13.sp,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}
