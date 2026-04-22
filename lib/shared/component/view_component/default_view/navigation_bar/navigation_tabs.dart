import 'package:flutter/material.dart';
import 'package:iamhere/core/router/app_routes.dart';

class NavigationTabs {
  static final List<NavTab> _navTabs = [
    NavTab(
      route: AppRoutes.geofence,
      label: '메인',
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on,
    ),
    NavTab(
      route: AppRoutes.contact,
      label: '친구',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    NavTab(
      route: AppRoutes.record,
      label: '기록',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
    ),
    NavTab(
      route: AppRoutes.setting,
      label: '설정',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
    ),
  ];

  static List<NavTab> get navTabs => _navTabs;
}

class NavTab {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  NavTab({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
