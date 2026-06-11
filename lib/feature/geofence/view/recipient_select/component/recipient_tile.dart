import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/model/recipient.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

const String _questionMark = '?';
const String _imHere = 'ImHere';

const List<Color> _avatarColors = [
  Color(0xFF7986CB), // Indigo
  Color(0xFF4DB6AC), // Teal
  Color(0xFF81C784), // Green
  Color(0xFFFFB74D), // Amber
  Color(0xFFE57373), // Red
  Color(0xFFBA68C8), // Purple
  Color(0xFF64B5F6), // Blue
  Color(0xFFFF8A65), // Orange
];

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
            _buildCircleAvatar(colorScheme),
            SizedBox(width: 16.w),
            _buildNameAndSubtitle(colorScheme),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAvatar(ColorScheme colorScheme) {
    final name = recipient.displayName;
    final baseColor = _colorFor(name);
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 24.r,
          backgroundColor: baseColor.withValues(alpha: isSelected ? 0.85 : 0.7),
          child: Text(
            name.isNotEmpty ? name[0] : _questionMark,
            style: AppTextStyles.hannaAirBold(18, Colors.white),
          ),
        ),
        if (isSelected)
          CircleAvatar(
            radius: 24.r,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.25),
          ),
      ],
    );
  }

  Color _colorFor(String name) {
    return _avatarColors[name.hashCode.abs() % _avatarColors.length];
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
      color: isSelected ? colorScheme.primary.withValues(alpha: 0.10) : null,
      border: Border(
        left: isSelected
            ? BorderSide(color: colorScheme.primary, width: 3.w)
            : BorderSide.none,
        bottom: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
    );
  }
}
