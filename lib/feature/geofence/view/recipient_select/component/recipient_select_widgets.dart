import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';

import 'recipient_select_constants.dart';

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
        children: [
          Checkbox(
            value: totalCount > 0 && isAllSelected,
            tristate: true,
            activeColor: cs.primary,
            onChanged: onToggle,
          ),
          Text(selectAll, style: AppTextStyles.hannaAirBold(16, cs.onSurface)),
          const Spacer(),
          Text(
            '$selectedCount$slash$totalCount',
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
