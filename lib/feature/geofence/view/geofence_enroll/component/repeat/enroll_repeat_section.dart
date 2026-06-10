import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/input/selection_chip.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/model/repeat_schedule.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component/common/enroll_section_label.dart';

const List<String> _dayLabels = ['일', '월', '화', '수', '목', '금', '토'];

class EnrollRepeatSection extends StatelessWidget {
  final RepeatSchedule selectedSchedule;
  final ValueChanged<RepeatSchedule>? onChanged;

  const EnrollRepeatSection({
    super.key,
    this.selectedSchedule = const RepeatSchedule(),
    this.onChanged,
  });

  void _toggleDay(int day) {
    final days = {...?selectedSchedule.customDays};
    if (!days.remove(day)) {
      days.add(day);
    }
    onChanged!(RepeatSchedule(type: RepeatType.custom, customDays: days));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final repeatTypes = RepeatType.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnrollSectionLabel('반복 설정'),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final type in repeatTypes)
              SelectionChip(
                label: type.displayName,
                isSelected: selectedSchedule.type == type,
                onTap: onChanged != null
                    ? () => onChanged!(RepeatSchedule(type: type))
                    : null,
              ),
          ],
        ),
        if (selectedSchedule.type == RepeatType.custom) ...[
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            children: [
              for (var day = 0; day < 7; day++)
                _DayChip(
                  label: _dayLabels[day],
                  isSelected:
                      selectedSchedule.customDays?.contains(day) ?? false,
                  onTap: onChanged != null ? () => _toggleDay(day) : null,
                ),
            ],
          ),
        ],
        SizedBox(height: 10.h),
        Text(
          '반복 알림은 준비 중이에요. 지금은 한 번만 알려주는 도착 알림을 만들 수 있어요.',
          style: AppTextStyles.hannaAirRegular(12, cs.onSurface.withValues(alpha: 0.72)),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DayChip({
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.hannaAirBold(
            12,
            isSelected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

