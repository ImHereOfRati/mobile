import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/input/selection_chip.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/model/event_type.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component/common/enroll_section_label.dart';

class EnrollEventSection extends StatelessWidget {
  final EventType selectedType;
  final ValueChanged<EventType>? onChanged;

  const EnrollEventSection({
    super.key,
    this.selectedType = EventType.arrival,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnrollSectionLabel('언제 알려드릴까요?'),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            SelectionChip(
              label: '도착했을 때',
              isSelected: selectedType == EventType.arrival,
              onTap: onChanged != null ? () => onChanged!(EventType.arrival) : null,
            ),
            const SelectionChip(
              label: '출발했을 때',
              isEnabled: false,
            ),
            const SelectionChip(
              label: '도착/출발 모두',
              isEnabled: false,
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            '이번 단계에서는 도착 알림을 먼저 지원해요. 출발 알림은 준비 중이에요.',
            style: AppTextStyles.hannaAirRegular(12, cs.onSurface.withValues(alpha: 0.72)),
          ),
        ),
      ],
    );
  }
}
