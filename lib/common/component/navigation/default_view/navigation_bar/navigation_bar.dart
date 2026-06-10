import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'center_add_button.dart';
import 'navigation_tabs.dart';
import 'tab_item.dart';

class MainBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(BuildContext, String) onTap;
  final void Function(BuildContext context) onCenterAddAuthorizedTap;
  final Future<void> Function(BuildContext context) onCenterAddUnauthorizedTap;

  const MainBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.onCenterAddAuthorizedTap,
    required this.onCenterAddUnauthorizedTap,
  });

  @override
  Widget build(BuildContext context) {
    final navigationTabs = NavigationTabs.navTabs;
    final cs = Theme.of(context).colorScheme;
    final dividerColor =
        Theme.of(context).dividerTheme.color ?? const Color(0xFFD2D2D7);

    final int centerIndex = navigationTabs.length ~/ 2;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Row(
            children: List.generate(navigationTabs.length + 1, (index) {
              if (index == centerIndex) {
                return Expanded(
                  flex: 2,
                  child: CenterAddButton(
                    onAuthorizedTap: onCenterAddAuthorizedTap,
                    onUnauthorizedTap: onCenterAddUnauthorizedTap,
                  ),
                );
              }

              final tabIdx = index > centerIndex ? index - 1 : index;
              final tab = navigationTabs[tabIdx];
              final isSelected = tabIdx == selectedIndex;

              return Expanded(
                flex: 2,
                child: TabItem(
                  tab: tab,
                  isSelected: isSelected,
                  onTap: () => onTap(context, tab.route),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
