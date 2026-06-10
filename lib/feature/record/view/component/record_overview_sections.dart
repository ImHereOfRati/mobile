import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/view_model/geofence_record_view_model.dart';

class RecordPageHeader extends StatelessWidget {
  final int count;

  const RecordPageHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('활동', style: tt.displayMedium),
          SizedBox(height: 4.h),
          Text('도착 알림과 받은 요청을 확인하세요', style: tt.bodyMedium),
          SizedBox(height: 4.h),
          Text(
            '$count개의 읽지 않은 항목',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

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

class RecordEmptySection extends StatelessWidget {
  final String message;

  const RecordEmptySection({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 14.sp,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class RecordErrorSection extends StatelessWidget {
  final WidgetRef ref;

  const RecordErrorSection({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록을 불러올 수 없습니다',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 14.sp,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 8.h),
          TextButton(
            onPressed: () => ref.read(geofenceRecordViewModelProvider.notifier).refresh(),
            child: Text(
              '다시 시도',
              style: TextStyle(fontFamily: 'BMHANNAAir', fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}
