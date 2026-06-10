import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'geofence_tile_info.dart';

class GeofenceTile extends StatelessWidget {
  final bool isToggleOn;
  final bool isAutoSendReady;
  final ValueChanged<bool> onToggleChanged;
  final String homeName;
  final String address;
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
            Expanded(
              child: GeofenceTileInfo(
                homeName: homeName,
                address: address,
                memberCount: memberCount,
                isToggleOn: isToggleOn,
                isAutoSendReady: isAutoSendReady,
              ),
            ),
            SizedBox(width: 8.w),
            _buildToggleSwitch(cs),
          ],
        ),
      ),
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
