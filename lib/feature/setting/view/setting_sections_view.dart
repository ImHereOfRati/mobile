import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/setting/view/my_info_view.dart';
import 'package:iamhere/feature/setting/view/privacy_view.dart';
import 'package:iamhere/feature/setting/view/setting_components.dart';
import 'package:iamhere/feature/setting/view/setting_diagnosis_section.dart';
import 'package:iamhere/feature/setting/view/setting_layout_components.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model_state.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/view/component/auto_send_readiness_card.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';
import 'package:iamhere/common/component/theme/theme_mode_provider.dart';

class SettingSectionsView extends StatelessWidget {
  final WidgetRef ref;
  final SettingViewModelState state;
  final bool isDark;
  final String batteryLabel;
  final String Function(PermissionState, {bool toggle}) permissionLabel;
  final Future<void> Function(BuildContext, WidgetRef, PermissionState, Future<void> Function()) onPermissionTap;
  final Future<void> Function(BuildContext, WidgetRef) onBatteryOptimizationTap;
  final Future<void> Function(BuildContext) onSupportTap;

  const SettingSectionsView({
    super.key,
    required this.ref,
    required this.state,
    required this.isDark,
    required this.batteryLabel,
    required this.permissionLabel,
    required this.onPermissionTap,
    required this.onBatteryOptimizationTap,
    required this.onSupportTap,
  });

  @override
  Widget build(BuildContext context) {
    final readiness = AutoSendReadiness(
      locationPermission: state.locationPermission,
      batteryOptimizationPermission: state.batteryOptimizationPermission,
    );

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        AutoSendReadinessCard(
          readiness: readiness,
          onTap: () => AppRoutes.pushUserPermission(context),
        ),
        SizedBox(height: 20.h),
        SettingSection(title: '계정', items: [_accountItem(context)]),
        SizedBox(height: 20.h),
        SettingSection(title: '디스플레이', items: [
          SettingThemeToggleItem(ref: ref, isDark: isDark),
        ]),
        SizedBox(height: 20.h),
        SettingSection(title: '앱 사용 권한', items: _permissionItems(context)),
        SizedBox(height: 20.h),
        SettingSection(title: '자동 전송 준비', items: _readinessItems(context, readiness)),
        SizedBox(height: 20.h),
        const SettingDiagnosisSection(),
        SizedBox(height: 20.h),
        SettingSection(title: '개인정보', items: _privacyItems(context)),
        SizedBox(height: 20.h),
        SettingSection(title: '고객 지원', items: [_supportItem(context)]),
        SizedBox(height: 20.h),
        SettingSection(title: '앱 정보', items: [_versionItem()]),
        SizedBox(height: 32.h),
        const SettingFooter(),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _accountItem(BuildContext context) {
    return SettingItem(
      title: '내 정보',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyInfoView()),
      ),
    );
  }

  List<Widget> _permissionItems(BuildContext context) {
    return [
      SettingItem(
        title: '앱 알림',
        trailingText: permissionLabel(state.pushPermission, toggle: true),
        onTap: () => onPermissionTap(
          context,
          ref,
          state.pushPermission,
          () => ref.read(settingViewModelProvider.notifier).requestPushPermission(),
        ),
      ),
      SettingItem(
        title: '도착 알림 위치 설정',
        trailingText: permissionLabel(state.locationPermission),
        onTap: () => onPermissionTap(
          context,
          ref,
          state.locationPermission,
          () => ref.read(settingViewModelProvider.notifier).requestLocationPermission(),
        ),
      ),
      SettingItem(
        title: '연락처 사용',
        trailingText: permissionLabel(state.contactPermission, toggle: true),
        onTap: () => onPermissionTap(
          context,
          ref,
          state.contactPermission,
          () => ref.read(settingViewModelProvider.notifier).requestContactPermission(),
        ),
      ),
    ];
  }

  List<Widget> _readinessItems(BuildContext context, AutoSendReadiness readiness) {
    return [
      SettingItem(
        title: '자동 전송 준비 보기',
        trailingText: readiness.isReady ? '완료' : '설정 필요',
        onTap: () => AppRoutes.pushUserPermission(context),
      ),
      SettingItem(
        title: '배터리 최적화 제외',
        trailingText: batteryLabel,
        onTap: () => onBatteryOptimizationTap(context, ref),
      ),
    ];
  }

  List<Widget> _privacyItems(BuildContext context) {
    return [
      SettingItem(
        title: '개인정보 보호 정책',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyView(title: '개인정보 보호 정책')),
        ),
      ),
      SettingItem(
        title: '서비스 이용약관',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyView(title: '서비스 이용약관')),
        ),
      ),
    ];
  }

  Widget _supportItem(BuildContext context) {
    return SettingItem(title: '문의하기', onTap: () => onSupportTap(context));
  }

  Widget _versionItem() {
    return SettingItem(
      title: '버전 정보',
      trailingText: state.appVersion.isEmpty ? '정보 없음' : state.appVersion,
    );
  }
}

class SettingThemeToggleItem extends StatelessWidget {
  final WidgetRef ref;
  final bool isDark;

  const SettingThemeToggleItem({super.key, required this.ref, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 20.r,
            color: cs.primary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '다크 모드',
              style: TextStyle(
                fontFamily: 'BMHANNAAir',
                fontSize: 16.sp,
                color: cs.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
          CupertinoSwitch(
            value: isDark,
            activeTrackColor: cs.primary,
            onChanged: (_) => ref.read(appThemeModeProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }
}
