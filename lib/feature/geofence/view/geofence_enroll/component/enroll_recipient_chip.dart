import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

class EnrollRecipientChip extends StatelessWidget {
  final Recipient recipient;
  const EnrollRecipientChip({super.key, required this.recipient});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isServer = recipient is ServerRecipient;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isServer ? Icons.cloud_outlined : Icons.person_outline,
            size: 14.r,
            color: cs.primary,
          ),
          SizedBox(width: 4.w),
          Text(
            recipient.displayName,
            style: AppTextStyles.hannaAirMedium(13, cs.primary),
          ),
        ],
      ),
    );
  }
}
