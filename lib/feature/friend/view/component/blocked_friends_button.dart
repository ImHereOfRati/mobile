import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

class BlockedFriendsButton extends StatelessWidget {
  const BlockedFriendsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: GestureDetector(
          onTap: () => AppRoutes.goToFriendRestrictions(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16.r,
                color: cs.onSurface.withValues(alpha: 0.38),
              ),
              SizedBox(width: 6.w),
              Text(
                '차단/거절한 친구 보기',
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 13.sp,
                  color: cs.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
