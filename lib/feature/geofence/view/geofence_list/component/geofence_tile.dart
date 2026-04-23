import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String _memberCountUnit = '명';

class GeofenceTile extends StatelessWidget {
  final bool isToggleOn;
  final ValueChanged<bool> onToggleChanged;
  final String homeName;
  final String address;
  final int memberCount;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const GeofenceTile({
    super.key,
    required this.isToggleOn,
    required this.onToggleChanged,
    required this.homeName,
    required this.address,
    required this.memberCount,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToggleOn ? cs.primary.withValues(alpha: 0.08) : cs.surface,
          borderRadius: BorderRadius.circular(8.r),
        ),
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Row(
          children: [
            SizedBox(width: 14.w),
            _buildInfoSection(cs),
            SizedBox(width: 8.w),
            _buildToggleSwitch(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme cs) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            homeName,
            style: AppTextStyles.gSansBold(19, cs.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),
          _buildSubInfoRow(cs),
        ],
      ),
    );
  }

  Widget _buildSubInfoRow(ColorScheme cs) {
    return Row(
      children: [
        _buildIconText(
          Icons.location_on_outlined,
          address,
          cs,
          isFlexible: true,
        ),
        SizedBox(width: 12.w),
        _buildIconText(
          Icons.people_outline,
          '$memberCount$_memberCountUnit',
          cs,
        ),
      ],
    );
  }

  Widget _buildIconText(
    IconData icon,
    String text,
    ColorScheme cs, {
    bool isFlexible = false,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.r, color: cs.onSurfaceVariant),
        SizedBox(width: 3.w),
        isFlexible
            ? Flexible(child: _subTextStyle(text, cs))
            : _subTextStyle(text, cs),
      ],
    );

    return isFlexible ? Flexible(child: content) : content;
  }

  Widget _subTextStyle(String text, ColorScheme cs) {
    return Text(
      text,
      style: AppTextStyles.hannaAirRegular(13, cs.onSurfaceVariant),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildToggleSwitch(ColorScheme cs) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: isToggleOn,
        onChanged: onToggleChanged,
        activeThumbColor: cs.onPrimary,
        activeTrackColor: cs.primary,
        inactiveThumbColor: cs.onSurfaceVariant,
        inactiveTrackColor: cs.onSurface.withValues(alpha: 0.15),
      ),
    );
  }
}
