import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:iamhere/feature/friend/view_model/friend_request_view_model.dart';

class FriendRequestRow extends ConsumerWidget {
  const FriendRequestRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final requestsAsync = ref.watch(friendRequestViewModelProvider);
    final count = requestsAsync.value?.length ?? 0;

    return GestureDetector(
      onTap: () => AppRoutes.goToFriendRequests(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        child: Row(
          children: [
            Text(
              '받은 친구 요청',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: count > 0 ? cs.primary : cs.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '$count건',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimary,
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.play_arrow_rounded, size: 20.r, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
