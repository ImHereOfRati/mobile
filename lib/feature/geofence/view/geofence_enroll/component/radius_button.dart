import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String _km = 'km';
const String _m = 'm';

class RadiusButton extends StatelessWidget {
  final int radius;
  final bool isSelected;
  final VoidCallback onTap;

  const RadiusButton({
    super.key,
    required this.radius,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          height: 52.h,
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              _label(radius),
              style: isSelected
                  ? AppTextStyles.hannaAirBold(15, cs.onPrimary)
                  : AppTextStyles.hannaAirRegular(
                      15,
                      cs.onSurface.withValues(alpha: 0.6),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _label(int r) => r >= 1000 ? '${r ~/ 1000}$_km' : '$r$_m';
}
