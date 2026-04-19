import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';

class RecipientTile extends StatelessWidget {
  final Recipient recipient;
  final bool isSelected;
  final VoidCallback onTap;

  const RecipientTile({
    super.key,
    required this.recipient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: _recipientDecoration(context),
        child: Row(
          children: [
            Checkbox(value: isSelected, onChanged: (_) => onTap()),
            SizedBox(width: 12.w),
            _buildCircleAvatar(colorScheme),
            SizedBox(width: 16.w),
            _buildNameAndSubtitle(colorScheme),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 24.sp),
          ],
        ),
      ),
    );
  }

  CircleAvatar _buildCircleAvatar(ColorScheme colorScheme) {
    final name = recipient.displayName;
    return CircleAvatar(
      radius: 24.r,
      backgroundColor: isSelected
          ? colorScheme.primary.withValues(alpha: 0.25)
          : colorScheme.onSurface.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Expanded _buildNameAndSubtitle(ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  recipient.displayName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (recipient is ServerRecipient) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'ImHere',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            recipient.displaySubtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _recipientDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null,
      border: Border(
        bottom: BorderSide(
          color:
              Theme.of(context).dividerTheme.color ??
              colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
    );
  }
}
