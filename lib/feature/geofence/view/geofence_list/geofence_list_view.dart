import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/geofence/view_model/main/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';

import 'component/geofence_list_body.dart';
import 'component/geofence_header.dart';

class GeofenceListView extends ConsumerWidget {
  const GeofenceListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsyncValue = ref.watch(geofenceViewModelProvider);
    final batteryAsyncValue = ref.watch(batteryOptimizationStatusProvider);

    final isAlwaysLocationMissing = permissionAsyncValue.maybeWhen(
      data: (status) => status != PermissionState.grantedAlways,
      orElse: () => false,
    );
    final isBatteryOptimizationMissing = batteryAsyncValue.maybeWhen(
      data: (status) => status != PermissionState.grantedAlways,
      orElse: () => false,
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GeofenceHeader(
            isAlwaysLocationMissing: isAlwaysLocationMissing,
            isBatteryOptimizationMissing: isBatteryOptimizationMissing,
          ),
        ),

        const GeofenceListBody(),
      ],
    );
  }
}
