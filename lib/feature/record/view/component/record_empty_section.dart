import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
