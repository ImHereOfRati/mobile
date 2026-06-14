import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'geofence_tile_info.dart';

class GeofenceTile extends StatelessWidget {
  final bool isToggleOn;
  final bool isAutoSendReady;
  final ValueChanged<bool> onToggleChanged;
  final String homeName;
  final String address;
  final String eventType;
  final int memberCount;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const GeofenceTile({
    super.key,
    required this.isToggleOn,
    required this.isAutoSendReady,
    required this.onToggleChanged,
    required this.homeName,
    required this.address,
    required this.eventType,
    required this.memberCount,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 활성 상태에 따른 카드 배경색, 보더색, 그림자 설정
    final backgroundColor = isToggleOn
        ? cs.primary.withValues(alpha: 0.04)
        : cs.surface;

    final borderColor = isToggleOn
        ? cs.primary.withValues(alpha: 0.2)
        : cs.onSurface.withValues(alpha: 0.08);

    final List<BoxShadow> shadows = isToggleOn
        ? [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6.r,
              offset: const Offset(0, 2),
            ),
          ];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: isToggleOn ? 1.5.r : 1.r),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            splashColor: cs.primary.withValues(alpha: 0.08),
            highlightColor: cs.primary.withValues(alpha: 0.03),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                children: [
                  _buildStatusIndicator(cs),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: GeofenceTileInfo(
                      homeName: homeName,
                      address: address,
                      eventType: eventType,
                      memberCount: memberCount,
                      isToggleOn: isToggleOn,
                      isAutoSendReady: isAutoSendReady,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  _buildToggleSwitch(cs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ColorScheme cs) {
    final indicatorColor = isToggleOn
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.35);

    final indicatorBgColor = isToggleOn
        ? cs.primary.withValues(alpha: 0.08)
        : cs.onSurface.withValues(alpha: 0.05);

    return Container(
      width: 42.r,
      height: 42.r,
      decoration: BoxDecoration(
        color: indicatorBgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isToggleOn ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
          color: indicatorColor,
          size: 18.r,
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(ColorScheme cs) {
    return Transform.scale(
      scale: 0.82,
      child: Switch(
        value: isToggleOn,
        onChanged: onToggleChanged,
        activeThumbColor: cs.onPrimary,
        activeTrackColor: cs.primary,
        inactiveThumbColor: cs.onSurface.withValues(alpha: 0.35),
        inactiveTrackColor: cs.onSurface.withValues(alpha: 0.08),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
