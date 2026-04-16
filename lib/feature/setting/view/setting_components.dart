import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingSectionHeader extends StatelessWidget {
  final String title;
  const SettingSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'BMHANNAAir',
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          letterSpacing: -0.12,
        ),
      ),
    );
  }
}

class SettingItem extends StatelessWidget {
  final String title;
  final String? trailingText;
  final bool isDestructive;
  final VoidCallback? onTap;

  const SettingItem({
    super.key,
    required this.title,
    this.trailingText,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive
        ? const Color(0xFFFF3B30)
        : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 16.sp,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: TextStyle(
                  fontFamily: 'BMHANNAAir',
                  fontSize: 14.sp,
                  color: const Color(0xFF0071E3),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.224,
                ),
              )
            else if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).dividerTheme.color,
              ),
          ],
        ),
      ),
    );
  }
}
