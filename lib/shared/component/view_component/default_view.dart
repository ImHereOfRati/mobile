import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/router/app_routes.dart';

class DefaultView extends ConsumerWidget {
  final Widget child;

  static final List<String> _tabs = AppRoutes.mainTabs;

  // 좌측 2개 탭 (메인, 친구)
  static const _leftTabs = [
    (Icons.location_on_outlined, Icons.location_on, '메인'),
    (Icons.people_outline, Icons.people, '친구'),
  ];

  // 우측 2개 탭 (기록, 설정) — _tabs 인덱스 2, 3에 대응
  static const _rightTabs = [
    (Icons.history_outlined, Icons.history, '기록'),
    (Icons.settings_outlined, Icons.settings, '설정'),
  ];

  const DefaultView({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouter.of(context).state.uri.toString();
    final idx = _tabs.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  void _onTap(BuildContext context, int tabIndex) {
    HapticFeedback.lightImpact();
    context.go(_tabs[tabIndex]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: child,
      bottomNavigationBar: _buildBottomNav(context, selectedIndex),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: Theme.of(context).dividerTheme.color,
        ),
      ),
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Text(
          'ImHere',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  // ── Bottom Navigation Bar ────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, int selectedIndex) {
    final cs = Theme.of(context).colorScheme;
    final dividerColor =
        Theme.of(context).dividerTheme.color ?? const Color(0xFFD2D2D7);
    final selectedColor = cs.primary;
    final unselectedColor =
        Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ??
        const Color(0xFF6E6E73);

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
            children: [
              // 좌측: 메인(0), 친구(1)
              ..._leftTabs.asMap().entries.map((entry) {
                final i = entry.key; // tab index 0 or 1
                final tab = entry.value;
                final selected = i == selectedIndex;
                return _buildTabItem(
                  context,
                  tab: tab,
                  selected: selected,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => _onTap(context, i),
                );
              }),

              // 중앙: 추가 버튼
              _buildCenterAddButton(context, cs),

              // 우측: 기록(2), 설정(3)
              ..._rightTabs.asMap().entries.map((entry) {
                final i = entry.key + 2; // tab index 2 or 3
                final tab = entry.value;
                final selected = i == selectedIndex;
                return _buildTabItem(
                  context,
                  tab: tab,
                  selected: selected,
                  selectedColor: selectedColor,
                  unselectedColor: unselectedColor,
                  onTap: () => _onTap(context, i),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context, {
    required (IconData, IconData, String) tab,
    required bool selected,
    required Color selectedColor,
    required Color unselectedColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? tab.$2 : tab.$1,
              size: 22.r,
              color: selected ? selectedColor : unselectedColor,
            ),
            SizedBox(height: 3.h),
            Text(
              tab.$3,
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 10.sp,
                color: selected ? selectedColor : unselectedColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(BuildContext context, ColorScheme cs) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          final location = GoRouter.of(context).state.uri.toString();
          if (location.startsWith(AppRoutes.contact)) {
            context.push(AppRoutes.contactAdd);
          } else {
            context.push(AppRoutes.geofenceEnroll);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.add_rounded, size: 22.r, color: cs.onPrimary),
            ),
            SizedBox(height: 2.h),
            Text(
              '추가',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 10.sp,
                color: cs.onSurface.withValues(alpha: 0.55),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
