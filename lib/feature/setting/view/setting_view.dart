import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model_state.dart';
import 'package:iamhere/common/component/theme/theme_mode_provider.dart';

import 'setting_sections_view.dart';
import 'setting_view_support.dart';

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
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
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
    return SettingSectionsView(
      ref: ref,
      state: state,
      isDark: isDark,
      batteryLabel: SettingLabelFormatter.battery(
        state.batteryOptimizationPermission,
      ),
      permissionLabel: SettingLabelFormatter.permission,
      onPermissionTap: SettingActionHandler.handlePermissionTap,
      onBatteryOptimizationTap: SettingActionHandler.handleBatteryOptimizationTap,
      onSupportTap: SettingActionHandler.openSupportPage,
    );
  }
}
