import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String _questionMark = '?';
const String _imHere = 'ImHere';

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
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: colorScheme.primary,
            ),
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
        name.isNotEmpty ? name[0] : _questionMark,
        style: AppTextStyles.hannaAirBold(
          18,
          isSelected
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
              _buildNameText(colorScheme),
              if (recipient is ServerRecipient) _buildImHereBadge(colorScheme),
            ],
          ),
          SizedBox(height: 4.h),
          _buildSubtitleText(colorScheme),
        ],
      ),
    );
  }

  Widget _buildNameText(ColorScheme cs) {
    return Flexible(
      child: Text(
        recipient.displayName,
        style: AppTextStyles.hannaAirBold(
          16,
          isSelected ? cs.primary : cs.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImHereBadge(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.only(left: 6.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          _imHere,
          style: AppTextStyles.hannaAirBold(10, cs.primary),
        ),
      ),
    );
  }

  Widget _buildSubtitleText(ColorScheme cs) {
    return Text(
      recipient.displaySubtitle,
      style: AppTextStyles.hannaAirRegular(
        14,
        cs.onSurface.withValues(alpha: 0.55),
      ),
    );
  }

  BoxDecoration _recipientDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null,
      border: Border(
        bottom: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
    );
  }
}
