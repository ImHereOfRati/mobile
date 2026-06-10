import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

/// 알약 모양 단일 선택 칩. 이벤트 타입/반복 설정 등 선택 UI 에서 공용으로 사용한다.
class SelectionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;

  const SelectionChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.isEnabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = isSelected
        ? cs.primaryContainer
        : (isEnabled ? cs.surface : cs.surfaceContainerHighest);
    final fgColor = isSelected
        ? cs.onPrimaryContainer
        : (isEnabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.45));

    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: isSelected ? cs.primary : cs.outlineVariant,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.hannaAirBold(13, fgColor),
      ),
    );

    return isEnabled && onTap != null
        ? GestureDetector(onTap: onTap, child: chip)
        : chip;
  }
}
