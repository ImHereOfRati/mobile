import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
