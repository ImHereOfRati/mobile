import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

import 'navigation_tabs.dart';

class TabItem extends StatelessWidget {
  final NavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const TabItem({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final unselectedColor =
        Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ??
        colorScheme.onPrimary;

    final color = isSelected ? colorScheme.primary : unselectedColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? tab.activeIcon : tab.icon,
            size: 22.r,
            color: color,
          ),
          SizedBox(height: 3.h),
          Text(
            tab.label,
            style: AppTextStyles.tooSmallReactiveColorDescription(color),
          ),
        ],
      ),
    );
  }
}
