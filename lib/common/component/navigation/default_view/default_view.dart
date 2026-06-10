import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'appbar/main_app_bar.dart';
import 'navigation_bar/navigation_tab_index_resolver.dart';
import 'navigation_bar/navigation_bar.dart';
import 'navigation_bar/navigation_tabs.dart';

class DefaultView extends ConsumerWidget {
  final Widget child;
  final navigationTabs = NavigationTabs.navTabs;
  final NavigationTabIndexResolver tabIndexResolver;
  final void Function(BuildContext context) onCenterAddAuthorizedTap;
  final Future<void> Function(BuildContext context) onCenterAddUnauthorizedTap;

  DefaultView({
    super.key,
    required this.child,
    required this.tabIndexResolver,
    required this.onCenterAddAuthorizedTap,
    required this.onCenterAddUnauthorizedTap,
  });

  int _selectedIndex(BuildContext context) {
    final location = GoRouter.of(context).state.uri.toString();
    return tabIndexResolver.resolve(location);
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
      appBar: const MainAppBar(),
      body: child,
      bottomNavigationBar: MainBottomNavigationBar(
        selectedIndex: selectedIndex,
        onTap: _onNavigationItemTap,
        onCenterAddAuthorizedTap: onCenterAddAuthorizedTap,
        onCenterAddUnauthorizedTap: onCenterAddUnauthorizedTap,
      ),
    );
  }
}
