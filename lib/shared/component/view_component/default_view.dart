import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/router/app_routes.dart';
import 'package:iamhere/router/router_provider.dart';

class DefaultView extends ConsumerWidget {
  final Widget child;

  static final List<String> _tabs = AppRoutes.mainTabs;

  static const _tabIcons = [
    (Icons.location_on_outlined, Icons.location_on, '지오펜스'),
    (Icons.people_outline, Icons.people, '연락처'),
    (Icons.history_outlined, Icons.history, '기록'),
    (Icons.settings_outlined, Icons.settings, '설정'),
  ];

  const DefaultView({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouter.of(context).state.uri.toString();
    final idx = _tabs.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    HapticFeedback.lightImpact();
    context.go(_tabs[index]);
  }

  bool _showFab(BuildContext context) {
    final loc = GoRouter.of(context).state.uri.toString();
    return loc == AppRoutes.geofence || loc == AppRoutes.record;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: _buildAppBar(context),
      body: child,
      bottomNavigationBar: _buildBottomNav(context, ref, selectedIndex),
      floatingActionButton: _showFab(context)
          ? _buildFab(context, router)
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFD2D2D7)),
      ),
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Text(
          'ImHere',
          style: TextStyle(
            fontFamily: 'GmarketSans',
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1D1F),
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int selectedIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFD2D2D7), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56.h,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final selected = i == selectedIndex;
              final tab = _tabIcons[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTap(context, ref, i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? tab.$2 : tab.$1,
                        size: 22.r,
                        color: selected
                            ? const Color(0xFF0071E3)
                            : const Color(0xFF6E6E73),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        tab.$3,
                        style: TextStyle(
                          fontFamily: 'BMHANNAAir',
                          fontSize: 10.sp,
                          color: selected
                              ? const Color(0xFF0071E3)
                              : const Color(0xFF6E6E73),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, router) {
    return FloatingActionButton(
      onPressed: () => router.go('/geofence/enroll'),
      backgroundColor: const Color(0xFF0071E3),
      foregroundColor: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: Icon(Icons.add_rounded, size: 26.r),
    );
  }
}
