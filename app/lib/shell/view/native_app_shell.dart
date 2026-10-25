import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iamhere/components/components.dart';

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
      final value when value.startsWith('/setting') => NativeShellTab.setting,
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

  static const _nativeRoots = ['/setting', '/friend', '/record'];

  /// 웹이 아니라 앱이 직접 그리는 경로. 웹에는 장소(/geofence)만 남아 있다.
  static bool isNativePath(String path) =>
      _nativeRoots.any((root) => path == root || path.startsWith('$root/'));

  /// 뒤로 갈 때 돌아갈 상위 경로. 최상위 탭이면 null.
  static String? parentOf(String path) {
    final normalized = _normalizePath(path);
    if (_mainPaths.contains(normalized)) return null;
    if (RegExp(r'^/friend/device-contact/[^/]+/edit$').hasMatch(normalized)) {
      return '/friend';
    }
    final segments = normalized.split('/')..removeWhere((part) => part.isEmpty);
    if (segments.length <= 1) return null;
    return '/${segments.take(segments.length - 1).join('/')}';
  }

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
    if (path == '/user-permission') return '권한 설정';
    if (path == '/location-permission-guide') return '위치 권한 안내';
    if (path == '/battery-optimization-guide') return '배터리 설정 안내';

    if (path == '/geofence/message') return '장소 추가';
    if (RegExp(r'^/geofence/[^/]+/edit$').hasMatch(path)) return '장소 수정';
    if (path.startsWith('/geofence')) return '장소';
    if (path == '/friend/add') return '친구 추가';
    if (path == '/friend/requests') return '친구 요청';
    if (path == '/friend/restrictions') return '차단·거절 관리';
    if (RegExp(r'^/friend/device-contact/[^/]+/edit$').hasMatch(path)) {
      return '연락처 수정';
    }
    if (path.startsWith('/friend')) return '친구';
    if (RegExp(r'^/record/notifications/[^/]+$').hasMatch(path)) {
      return '받은 알림 상세';
    }
    if (path == '/record/notifications') return '받은 알림';
    if (RegExp(r'^/record/send-history/[^/]+$').hasMatch(path)) {
      return '전송 기록 상세';
    }
    if (path == '/record/send-history') return '전송 기록';
    if (path.startsWith('/record')) return '기록';
    if (path == '/setting') return '설정';
    if (path == '/setting/agreements') return '약관 동의 관리';
    return 'ImHere';
  }
}

/// 앱 공통 껍데기. 위쪽은 ImHere 로고 앱바 하나만 쓰고, 아래쪽은 하단
/// 네비게이션을 그린다. 화면 제목이나 뒤로 가기 버튼은 두지 않는다.
class NativeAppShell extends StatelessWidget {
  final Widget child;
  final NativeShellPage page;
  final ValueChanged<String> onNavigate;

  const NativeAppShell({
    super.key,
    required this.child,
    required this.page,
    required this.onNavigate,
  });

  static const _tabs = [
    (tab: NativeShellTab.geofence, path: '/geofence'),
    (tab: NativeShellTab.friend, path: '/friend'),
    (tab: NativeShellTab.record, path: '/record'),
    (tab: NativeShellTab.setting, path: '/setting'),
  ];

  static const _navItems = [
    ImHereNavItem(glyph: ImHereGlyph.place, label: '장소'),
    ImHereNavItem(glyph: ImHereGlyph.friends, label: '친구'),
    ImHereNavItem(glyph: ImHereGlyph.history, label: '기록'),
    ImHereNavItem(glyph: ImHereGlyph.settings, label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedTab = page.selectedTab;

    return Scaffold(
      backgroundColor: ImHereColors.of(context).background,
      body: Column(
        children: [
          ImHereAppHeader(
            onNotificationTap: () => onNavigate('/record/notifications'),
          ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: selectedTab == null
          ? null
          : ImHereNavigation(
              items: _navItems,
              index: _tabs.indexWhere((item) => item.tab == selectedTab),
              onChanged: (index) {
                HapticFeedback.lightImpact();
                onNavigate(_tabs[index].path);
              },
            ),
    );
  }
}
