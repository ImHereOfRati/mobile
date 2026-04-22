import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/core/router/app_routes.dart';

import 'appbar/main_app_bar.dart';
import 'navigation_bar/navigation_bar.dart';
import 'navigation_bar/navigation_tabs.dart';

class DefaultView extends ConsumerWidget {
  final Widget child;
  final navigationTabs = NavigationTabs.navTabs;

  DefaultView({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouter.of(context).state.uri.toString();
    final idx = AppRoutes.mainTabs.indexWhere((p) => location.startsWith(p));
    return idx < 0 ? 0 : idx;
  }

  void _onNavigationItemTap(BuildContext context, String route) {
    HapticFeedback.lightImpact();
    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MainAppBar(),
      body: child,
      bottomNavigationBar: MainBottomNavigationBar(
        selectedIndex: selectedIndex,
        onTap: _onNavigationItemTap,
      ),
    );
  }
}
