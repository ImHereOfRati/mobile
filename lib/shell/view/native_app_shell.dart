import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iamhere/shell/shell_theme.dart';

enum NativeShellTab { geofence, friend, record, setting }

class NativeShellPage {
  final String path;
  final String title;
  final NativeShellTab? selectedTab;
  final bool showBackButton;

  const NativeShellPage({
    required this.path,
    required this.title,
    required this.selectedTab,
    required this.showBackButton,
  });

  factory NativeShellPage.fromLocation(String location, {String? title}) {
    final path = _normalizePath(location);
    final selectedTab = switch (path) {
      final value when value.startsWith('/geofence') => NativeShellTab.geofence,
      final value when value.startsWith('/friend') => NativeShellTab.friend,
      final value when value.startsWith('/record') => NativeShellTab.record,
      '/setting' => NativeShellTab.setting,
      _ => null,
    };

    return NativeShellPage(
      path: path,
      title: title?.trim().isNotEmpty == true ? title!.trim() : _titleFor(path),
      selectedTab: selectedTab,
      showBackButton:
          _mainPaths.contains(path) == false && path != '/' && path != '/auth',
    );
  }

  static const _mainPaths = {'/geofence', '/friend', '/record', '/setting'};

  static String _normalizePath(String location) {
    final parsed = Uri.tryParse(location);
    var path = parsed?.path ?? location;
    path = path.replaceFirst(
      RegExp(r'^/app/(?:releases/[0-9a-fA-F]{40}/)?'),
      '/',
    );
    if (path.isEmpty) return '/';
    return path.startsWith('/') ? path : '/$path';
  }

  static String _titleFor(String path) {
    if (path == '/' || path == '/auth') return 'ImHere';
    if (path == '/terms-consent') return '약관 동의';
    if (path.startsWith('/terms-detail/')) return '약관 상세';
    if (path == '/user-permission') return '권한 설정';
    if (path == '/location-permission-guide') return '위치 권한 안내';
    if (path == '/battery-optimization-guide') return '배터리 설정 안내';
    if (path == '/catalog') return '디자인 시스템';
    if (path == '/geofence/message') return '장소 추가';
    if (RegExp(r'^/geofence/[^/]+/edit$').hasMatch(path)) return '장소 수정';
    if (path.startsWith('/geofence')) return '장소';
    if (path == '/friend/add') return '친구 추가';
    if (path == '/friend/requests') return '친구 요청';
    if (path == '/friend/restrictions') return '차단·거절 관리';
    if (path.startsWith('/friend')) return '친구';
    if (RegExp(r'^/record/notifications/[^/]+$').hasMatch(path)) {
      return '받은 알림 상세';
    }
    if (path == '/record/notifications') return '받은 알림';
    if (path == '/record/friend-requests') return '친구 요청 기록';
    if (RegExp(r'^/record/send-history/[^/]+$').hasMatch(path)) {
      return '전송 기록 상세';
    }
    if (path == '/record/send-history') return '전송 기록';
    if (path.startsWith('/record')) return '기록';
    if (path == '/setting') return '설정';
    return 'ImHere';
  }
}

class NativeAppShell extends StatelessWidget {
  final Widget child;
  final NativeShellPage page;
  final ValueChanged<String> onNavigate;
  final VoidCallback onBack;

  const NativeAppShell({
    super.key,
    required this.child,
    required this.page,
    required this.onNavigate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          'ImHere',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: page.showBackButton
            ? [
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: page.selectedTab == null
          ? null
          : _NativeBottomNavigation(
              selectedTab: page.selectedTab!,
              onNavigate: onNavigate,
            ),
    );
  }
}

class _NativeBottomNavigation extends StatelessWidget {
  final NativeShellTab selectedTab;
  final ValueChanged<String> onNavigate;

  const _NativeBottomNavigation({
    required this.selectedTab,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _tab(
                context,
                tab: NativeShellTab.geofence,
                path: '/geofence',
                label: '장소',
                icon: Icons.location_on_outlined,
                selectedIcon: Icons.location_on_rounded,
              ),
              _tab(
                context,
                tab: NativeShellTab.friend,
                path: '/friend',
                label: '친구',
                icon: Icons.people_outline_rounded,
                selectedIcon: Icons.people_rounded,
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: '장소 추가',
                  child: InkResponse(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onNavigate('/geofence/message');
                    },
                    radius: 28,
                    child: const Center(
                      child: SizedBox.square(
                        dimension: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: ShellTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _tab(
                context,
                tab: NativeShellTab.record,
                path: '/record',
                label: '기록',
                icon: Icons.history_rounded,
                selectedIcon: Icons.history_rounded,
              ),
              _tab(
                context,
                tab: NativeShellTab.setting,
                path: '/setting',
                label: '설정',
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(
    BuildContext context, {
    required NativeShellTab tab,
    required String path,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
  }) {
    final selected = tab == selectedTab;
    final mutedColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.56);
    final color = selected ? ShellTheme.primaryBlue : mutedColor;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkResponse(
          onTap: () {
            HapticFeedback.lightImpact();
            onNavigate(path);
          },
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? selectedIcon : icon, color: color, size: 23),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
