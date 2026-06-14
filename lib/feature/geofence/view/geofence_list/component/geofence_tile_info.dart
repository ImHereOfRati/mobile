import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';

import 'geofence_readiness_chip.dart';

const String _memberCountUnit = '명';

/// 알림 카드의 정보 영역 (이름 / 주소·수신자 수 / 준비 상태 칩).
class GeofenceTileInfo extends StatelessWidget {
  final String homeName;
  final String address;
  final String eventType;
  final int memberCount;
  final bool isToggleOn;
  final bool isAutoSendReady;

  const GeofenceTileInfo({
    super.key,
    required this.homeName,
    required this.address,
    required this.eventType,
    required this.memberCount,
    required this.isToggleOn,
    required this.isAutoSendReady,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleColor = isToggleOn
        ? cs.onSurface
        : cs.onSurface.withValues(alpha: 0.55);
    final subColor = isToggleOn
        ? cs.onSurfaceVariant
        : cs.onSurfaceVariant.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          homeName,
          style: AppTextStyles.gSansBold(18, titleColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        Text(
          EventType.fromName(eventType).displayName,
          style: AppTextStyles.hannaAirRegular(12, cs.primary),
        ),
        SizedBox(height: 5.h),
        _buildSubInfoRow(cs, subColor),
        SizedBox(height: 8.h),
        GeofenceReadinessChip(
          isToggleOn: isToggleOn,
          isAutoSendReady: isAutoSendReady,
        ),
      ],
    );
  }

  Widget _buildSubInfoRow(ColorScheme cs, Color textColor) {
    return Row(
      children: [
        Flexible(
          child: _IconText(
            icon: Icons.location_on_outlined,
            text: address,
            textColor: textColor,
            isFlexible: true,
          ),
        ),
        SizedBox(width: 12.w),
        _IconText(
          icon: Icons.people_outline,
          text: '$memberCount$_memberCountUnit',
          textColor: textColor,
        ),
      ],
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;
  final bool isFlexible;

  const _IconText({
    required this.icon,
    required this.text,
    required this.textColor,
    this.isFlexible = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: AppTextStyles.hannaAirRegular(12, textColor),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 13.r, color: textColor),
        SizedBox(width: 4.w),
        isFlexible ? Flexible(child: label) : label,
      ],
    );
  }
}
