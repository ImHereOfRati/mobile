import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'geofence_list_actions.dart';
import 'geofence_empty_state.dart';
import 'geofence_list_tile.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/feature/user_permission/view_model/auto_send_readiness_provider.dart';
import 'package:iamhere/common/component/style/app_text_styles.dart';
import 'package:iamhere/common/component/layout/loading_body.dart';
import 'package:iamhere/common/component/layout/sliver_message_view.dart';

class GeofenceListBody extends ConsumerStatefulWidget {
  const GeofenceListBody({super.key});

  @override
  ConsumerState<GeofenceListBody> createState() => _GeofenceListBodyState();
}

class _GeofenceListBodyState extends ConsumerState<GeofenceListBody>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(geofenceListViewModelProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final geofencesAsync = ref.watch(geofenceListViewModelProvider);
    final cs = Theme.of(context).colorScheme;

    return geofencesAsync.when(
      loading: () => const LoadingBody(),
      error: (err, _) => SliverMessageView(message: '오류 발생: $err', style: AppTextStyles.hannaAirRegular(16, cs.error)),
      data: (geofences) {
        if (geofences.isEmpty) {
          return const GeofenceEmptyState();
        }

        return GeofenceListTile(
          geofences: geofences,
          isAutoSendReady: ref.watch(autoSendReadinessProvider).isReady,
          onToggle: (geofence, newValue) => handleToggle(context, ref, geofence, newValue),
          onDelete: (geofence) => handleDelete(context, ref, geofence),
          onEdit: (geofence) => handleEdit(context, ref, geofence),
          onCreateNew: () => handleCreateNew(context, ref),
        );
      },
    );
  }
}
