import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TargetTile extends StatelessWidget {
  final String receiver;
  const TargetTile({super.key, required this.receiver});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.all(Radius.circular(5.r)),
          ),
          child: Center(
            child: Text(
              receiver,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        Text("에게", style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
