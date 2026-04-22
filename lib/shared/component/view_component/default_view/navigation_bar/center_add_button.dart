import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class CenterAddButton extends StatelessWidget {
  const CenterAddButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.geofenceEnroll);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, size: 22.r, color: cs.onPrimary),
          ),
          SizedBox(height: 2.h),
          Text('추가', style: AppTextStyles.smallGreyDescription(cs)),
        ],
      ),
    );
  }
}
