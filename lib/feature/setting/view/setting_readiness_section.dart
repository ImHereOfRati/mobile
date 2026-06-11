import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model_state.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/infrastructure/routing/app_routes.dart';

import 'setting_components.dart';
import 'setting_layout_components.dart';

/// 자동 전송 준비 섹션 (준비 상태 보기 / 배터리 최적화 제외).
class SettingReadinessSection extends ConsumerWidget {
  final SettingViewModelState state;
  final AutoSendReadiness readiness;

  const SettingReadinessSection({
    super.key,
    required this.state,
    required this.readiness,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingSection(
      title: '자동 전송 준비',
      items: [
        SettingItem(
          title: '자동 전송 준비 상태',
          trailingText: readiness.isReady ? '완료' : '설정 필요',
          onTap: () => AppRoutes.pushUserPermission(context),
        ),
      ],
    );
  }
}
