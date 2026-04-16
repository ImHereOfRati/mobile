import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model_state.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/shared/component/theme/theme_mode_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'privacy_view.dart';
import 'setting_components.dart';

class SettingView extends ConsumerWidget {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(settingViewModelProvider);
    final isDark = ref.watch(
      appThemeModeProvider.select((m) => m == ThemeMode.dark),
    );

    return Scaffold(
      body: stateAsync.when(
        data: (state) => _buildList(context, ref, state, isDark),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0071E3)),
        ),
        error: (_, __) => const Center(child: Text('설정을 불러오는 중 오류가 발생했습니다.')),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    SettingViewModelState state,
    bool isDark,
  ) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        _buildSection(context, '디스플레이', [
          _buildThemeToggleItem(context, ref, isDark),
        ]),
        SizedBox(height: 20.h),
        _buildSection(context, '권한', [
          SettingItem(
            title: '푸시 알림',
            trailingText: _permLabel(state.pushPermission, toggle: true),
          ),
          SettingItem(
            title: '메시지 알림',
            trailingText: _permLabel(state.pushPermission, toggle: true),
          ),
          SettingItem(
            title: '위치 추적',
            trailingText: _permLabel(state.locationPermission),
          ),
          const SettingItem(title: '위치 기록 보관', trailingText: '30일'),
        ]),
        SizedBox(height: 20.h),
        _buildSection(context, '개인정보', [
          SettingItem(
            title: '개인정보 보호 정책',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrivacyView(title: '개인정보 보호 정책'),
              ),
            ),
          ),
          SettingItem(
            title: '서비스 이용약관',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrivacyView(title: '서비스 이용약관'),
              ),
            ),
          ),
        ]),
        SizedBox(height: 20.h),
        _buildSection(context, '고객 지원', [
          SettingItem(
            title: '문의하기',
            onTap: () async {
              final url = Uri.parse(
                'https://dsko.notion.site/d75b9924c10c47f0b91e4da6ee4251ec?pvs=105',
              );
              if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('문의하기 페이지를 열 수 없습니다.')),
                  );
                }
              }
            },
          ),
        ]),
        SizedBox(height: 20.h),
        _buildSection(context, '앱 정보', [
          SettingItem(
            title: '버전 정보',
            trailingText: state.appVersion.isEmpty ? '정보 없음' : state.appVersion,
          ),
        ]),
        SizedBox(height: 32.h),
        _buildFooter(context),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.12,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              return Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 16.w,
                      color: Theme.of(context).dividerTheme.color,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggleItem(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 20.r,
            color: const Color(0xFF0071E3),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '다크 모드',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          CupertinoSwitch(
            value: isDark,
            activeTrackColor: const Color(0xFF0071E3),
            onChanged: (_) => ref.read(appThemeModeProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }

  String _permLabel(PermissionState state, {bool toggle = false}) {
    if (toggle) {
      return (state == PermissionState.grantedAlways ||
              state == PermissionState.grantedWhenInUse)
          ? '켜짐'
          : '꺼짐';
    }
    switch (state) {
      case PermissionState.grantedAlways:
        return '항상 허용';
      case PermissionState.grantedWhenInUse:
        return '사용 중 허용';
      default:
        return '거부됨';
    }
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'Imhere © 2025',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.12,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '위치 기반 알림 서비스',
            style: TextStyle(
              fontFamily: 'BMHANNAAir',
              fontSize: 12.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
              letterSpacing: -0.12,
            ),
          ),
        ],
      ),
    );
  }
}
