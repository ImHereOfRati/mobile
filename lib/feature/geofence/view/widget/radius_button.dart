import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
              color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              _label(radius),
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 15.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _label(int r) => r >= 1000 ? '${r ~/ 1000}km' : '${r}m';
}
