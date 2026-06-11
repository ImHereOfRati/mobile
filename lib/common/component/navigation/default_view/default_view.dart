import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/feature/user_permission/view/user_permission_prep_overlay.dart';
import 'package:iamhere/feature/user_permission/view/user_permission_prep_view.dart';
import 'package:iamhere/feature/user_permission/view_model/show_permission_prep_provider.dart';

import 'appbar/main_app_bar.dart';
import 'navigation_bar/navigation_bar.dart';
import 'navigation_bar/navigation_tab_index_resolver.dart';
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
    final showPermissionPrep = ref.watch(showPermissionPrepProvider);
    final locationAsync = ref.watch(geofenceViewModelProviderForPrep);
    final batteryAsync = ref.watch(batteryOptimizationStatusProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const MainAppBar(),
      body: Stack(
        children: [
          child,
          if (showPermissionPrep)
            locationAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (locationStatus) {
                final batteryStatus = batteryAsync.maybeWhen(
                  data: (status) => status,
                  orElse: () => PermissionState.denied,
                );
                final readiness = AutoSendReadiness(
                  locationPermission: locationStatus,
                  batteryOptimizationPermission: batteryStatus,
                );
                return UserPermissionPrepOverlay(readiness: readiness);
              },
            ),
        ],
      ),
      bottomNavigationBar: MainBottomNavigationBar(
        selectedIndex: selectedIndex,
        onTap: _onNavigationItemTap,
        onCenterAddAuthorizedTap: onCenterAddAuthorizedTap,
        onCenterAddUnauthorizedTap: onCenterAddUnauthorizedTap,
      ),
    );
  }
}
