import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String activateToggleTitle = '위치 알람 활성화';

class EnrollActivateToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const EnrollActivateToggle({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: cs.onSurface.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            activateToggleTitle,
            style: AppTextStyles.hannaAirBold(15, cs.onSurface),
          ),
          const Spacer(),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeThumbColor: cs.primary,
          ),
        ],
      ),
    );
  }
}
