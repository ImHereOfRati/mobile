import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 공통 선택 버튼 컴포넌트
class SelectButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isSelected;
  final double? minHeight;

  const SelectButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22.sp),
      label: Text(label, style: TextStyle(fontSize: 16.sp)),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, minHeight ?? 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade400,
          width: isSelected ? 2.w : 1.w,
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h),
      ),
    );
  }
}
