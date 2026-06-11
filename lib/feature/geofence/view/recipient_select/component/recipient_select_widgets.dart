import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

import 'recipient_select_constants.dart';

class _SelectCountText extends StatelessWidget {
  final int selectedCount;
  final int totalCount;

  const _SelectCountText({
    required this.selectedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (selectedCount == 0) {
      return Text(
        '전체 $totalCount$memberCountUnit',
        style: AppTextStyles.hannaAirRegular(
          14,
          cs.onSurface.withValues(alpha: 0.55),
        ),
      );
    }
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$selectedCount',
            style: AppTextStyles.hannaAirBold(14, cs.primary),
          ),
          TextSpan(
            text: selectedCountSuffix,
            style: AppTextStyles.hannaAirRegular(
              14,
              cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipientSelectHeader extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onConfirm;

  const RecipientSelectHeader({
    super.key,
    required this.selectedCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.onSurface.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$selectRecipientTitle ($selectedCount$memberCountUnit)',
            style: AppTextStyles.gSansBold(18, cs.onSurface),
          ),
          IconButton(
            icon: Icon(Icons.check, size: 28.sp, color: cs.primary),
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

class RecipientSelectAllRow extends StatelessWidget {
  final bool isAllSelected;
  final int selectedCount;
  final int totalCount;
  final ValueChanged<bool?> onToggle;

  const RecipientSelectAllRow({
    super.key,
    required this.isAllSelected,
    required this.selectedCount,
    required this.totalCount,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onToggle(isAllSelected ? false : null),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            bottom: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: totalCount > 0 && isAllSelected,
              tristate: true,
              activeColor: cs.primary,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return cs.primary;
                return null;
              }),
              onChanged: onToggle,
            ),
            Text(selectAll, style: AppTextStyles.hannaAirBold(16, cs.onSurface)),
            const Spacer(),
            _SelectCountText(selectedCount: selectedCount, totalCount: totalCount),
          ],
        ),
      ),
    );
  }
}
