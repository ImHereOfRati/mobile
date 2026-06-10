import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/feature/geofence/view_model/main/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';

import 'gps_status_badge.dart';

class GPSStatusCard extends ConsumerStatefulWidget {
  const GPSStatusCard({super.key});

  @override
  ConsumerState<GPSStatusCard> createState() => _GPSStatusCardState();
}

class _GPSStatusCardState extends ConsumerState<GPSStatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(geofenceViewModelProvider);
    final geofenceList = ref.watch(geofenceListViewModelProvider);

    return permissionState.maybeWhen(
      data: (status) {
        bool isTracking = _checkTrackingStatus(geofenceList, status);
        bool isServiceDisabled = status == PermissionState.serviceDisabled;

        return GPSStatusBadge(
          isTracking: isTracking,
          isServiceDisabled: isServiceDisabled,
          animation: _controller,
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  bool _checkTrackingStatus(
    AsyncValue<List<GeofenceEntity>> geofenceList,
    PermissionState status,
  ) {
    final hasActiveGeofence = geofenceList.maybeWhen(
      data: (list) => list.any((item) => item.isActive),
      orElse: () => false,
    );
    final isAlwaysGranted = (status == PermissionState.grantedAlways);
    final isTracking = isAlwaysGranted && hasActiveGeofence;
    return isTracking;
  }
}
