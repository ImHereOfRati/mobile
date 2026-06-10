import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model_state.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';

import 'setting_components.dart';
import 'setting_layout_components.dart';
import 'setting_view_support.dart';

/// 앱 사용 권한 섹션 (앱 알림 / 위치 / 연락처).
class SettingPermissionSection extends ConsumerWidget {
  final SettingViewModelState state;

  const SettingPermissionSection({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingSection(
      title: '앱 사용 권한',
      items: [
        _item(
          context,
          ref,
          title: '앱 알림',
          status: state.pushPermission,
          isToggleLabel: true,
          request: () => ref
              .read(settingViewModelProvider.notifier)
              .requestPushPermission(),
        ),
        _item(
          context,
          ref,
          title: '도착 알림 위치 설정',
          status: state.locationPermission,
          request: () => ref
              .read(settingViewModelProvider.notifier)
              .requestLocationPermission(),
        ),
        _item(
          context,
          ref,
          title: '연락처 사용',
          status: state.contactPermission,
          isToggleLabel: true,
          request: () => ref
              .read(settingViewModelProvider.notifier)
              .requestContactPermission(),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required PermissionState status,
    required Future<void> Function() request,
    bool isToggleLabel = false,
  }) {
    return SettingItem(
      title: title,
      trailingText:
          SettingLabelFormatter.permission(status, toggle: isToggleLabel),
      onTap: () => SettingActionHandler.handlePermissionTap(
        context,
        ref,
        status,
        request,
      ),
    );
  }
}
