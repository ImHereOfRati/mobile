import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';
import 'package:iamhere/feature/setting/view_model/setting_view_model.dart';

import 'setting_sections_view.dart';

class SettingView extends ConsumerWidget {
  const SettingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(settingViewModelProvider);

    return Scaffold(
      body: stateAsync.when(
        data: (state) => SettingSectionsView(state: state),
        loading: () => Center(
          child: ImHereLoadingIndicator(height: 30),
        ),
        error: (_, __) => const Center(child: Text('설정을 불러오는 중 오류가 발생했습니다.')),
      ),
    );
  }
}
