import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/record/view_model/geofence_record_view_model.dart';

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
            '활동 기록을 불러올 수 없습니다',
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
