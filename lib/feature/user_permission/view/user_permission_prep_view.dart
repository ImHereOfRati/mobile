import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';
import 'package:iamhere/feature/geofence/view_model/main/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/auto_send_readiness.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';

import 'component/user_permission_prep_components.dart';

class UserPermissionPrepView extends ConsumerWidget {
  const UserPermissionPrepView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(geofenceViewModelProviderForPrep);
    final batteryAsync = ref.watch(batteryOptimizationStatusProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: locationAsync.when(
          loading: () => const Center(child: ImHereLoadingIndicator(height: 32)),
          error: (_, __) => _buildErrorState(context, cs),
          data: (locationStatus) {
            final batteryStatus = batteryAsync.maybeWhen(
              data: (status) => status,
              orElse: () => PermissionState.denied,
            );
            final readiness = AutoSendReadiness(
              locationPermission: locationStatus,
              batteryOptimizationPermission: batteryStatus,
            );
            return UserPermissionPrepBody(readiness: readiness);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme cs) {
    return Center(
      child: Text(
        '준비 상태를 불러오지 못했어요.',
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: cs.onSurface),
      ),
    );
  }
}

final geofenceViewModelProviderForPrep = FutureProvider<PermissionState>((
  ref,
) async {
  return ref.watch(geofenceViewModelProvider.future);
});
