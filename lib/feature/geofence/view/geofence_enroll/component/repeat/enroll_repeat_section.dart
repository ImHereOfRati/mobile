import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/feature/geofence/view/geofence_enroll/component/common/enroll_section_label.dart';

class EnrollRepeatSection extends StatelessWidget {
  const EnrollRepeatSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const labels = ['반복 안 함', '매일', '평일', '주말', '직접 설정'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EnrollSectionLabel('반복 설정'),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final label in labels)
              _RepeatChip(label: label, isSelected: label == '반복 안 함'),
          ],
        ),
        SizedBox(height: 10.h),
        Text(
          '반복 알림은 준비 중이에요. 지금은 한 번만 알려주는 도착 알림을 만들 수 있어요.',
          style: AppTextStyles.hannaAirRegular(12, cs.onSurface.withValues(alpha: 0.72)),
        ),
      ],
    );
  }
}

class _RepeatChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _RepeatChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: isSelected ? cs.primary : cs.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.hannaAirBold(
          13,
          isSelected
              ? cs.onPrimaryContainer
              : cs.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
