import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

import 'geofence_readiness_chip.dart';

const String _memberCountUnit = '명';

/// 알림 카드의 정보 영역 (이름 / 주소·수신자 수 / 준비 상태 칩).
class GeofenceTileInfo extends StatelessWidget {
  final String homeName;
  final String address;
  final int memberCount;
  final bool isToggleOn;
  final bool isAutoSendReady;

  const GeofenceTileInfo({
    super.key,
    required this.homeName,
    required this.address,
    required this.memberCount,
    required this.isToggleOn,
    required this.isAutoSendReady,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
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
        SizedBox(height: 8.h),
        GeofenceReadinessChip(
          isToggleOn: isToggleOn,
          isAutoSendReady: isAutoSendReady,
        ),
      ],
    );
  }

  Widget _buildSubInfoRow(ColorScheme cs) {
    return Row(
      children: [
        Flexible(
          child: _IconText(
            icon: Icons.location_on_outlined,
            text: address,
            isFlexible: true,
          ),
        ),
        SizedBox(width: 12.w),
        _IconText(
          icon: Icons.people_outline,
          text: '$memberCount$_memberCountUnit',
        ),
      ],
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isFlexible;

  const _IconText({
    required this.icon,
    required this.text,
    this.isFlexible = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = Text(
      text,
      style: AppTextStyles.hannaAirRegular(13, cs.onSurfaceVariant),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.r, color: cs.onSurfaceVariant),
        SizedBox(width: 3.w),
        isFlexible ? Flexible(child: label) : label,
      ],
    );
  }
}
