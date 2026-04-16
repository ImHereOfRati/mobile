import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationListView extends ConsumerWidget {
  const NotificationListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '받은 알림',
          style: TextStyle(
            fontFamily: 'BMHANNAAir',
            fontSize: 18.sp,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 48.r,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 12.h),
            Text(
              '받은 알림이 없습니다',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 15.sp,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
