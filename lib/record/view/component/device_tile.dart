import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/record/repository/geofence_record_entity.dart';

class DeviceTile extends StatelessWidget {
  final SendMachine sendMachine;

  const DeviceTile({super.key, required this.sendMachine});

  @override
  Widget build(BuildContext context) {
    final String description = sendMachine.description;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(Radius.circular(5.r)),
      ),
      child: Center(
        child: Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 15.sp, // 폰트 크기
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
