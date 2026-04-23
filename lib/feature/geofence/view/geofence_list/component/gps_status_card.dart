import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/feature/geofence/view_model/main/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/shared/component/style/app_text_styles.dart';

const String _trackingActive = '위치 추적 중이에요';
const String _trackingInactive = '위치 추적을 하고 있지 않아요';
const String _serviceDisabled = 'GPS가 꺼져 있어요';

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
    final cs = Theme.of(context).colorScheme;

    return permissionState.maybeWhen(
      data: (status) {
        bool isTracking = _checkTrackingStatus(geofenceList, status);
        bool isServiceDisabled = status == PermissionState.serviceDisabled;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isTracking
                ? cs.primary
                : (isServiceDisabled
                    ? cs.errorContainer
                    : cs.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: _buildContents(isTracking, isServiceDisabled, cs),
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

  Row _buildContents(bool isTracking, bool isServiceDisabled, ColorScheme cs) {
    String text = isTracking ? _trackingActive : _trackingInactive;
    if (isServiceDisabled) text = _serviceDisabled;

    return Row(
      children: [
        _buildGPSIcon(isTracking, isServiceDisabled, cs),
        SizedBox(width: 8.w),
        Text(
          text,
          style: AppTextStyles.hannaAirBold(
            14,
            isTracking
                ? cs.onPrimary
                : (isServiceDisabled ? cs.error : cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildGPSIcon(
    bool isTracking,
    bool isServiceDisabled,
    ColorScheme cs,
  ) {
    final icon = Icon(
      isServiceDisabled
          ? Icons.location_off_outlined
          : Icons.location_on_outlined,
      color: selectColor(isTracking, isServiceDisabled, cs),
      size: 20.sp,
    );

    return selectIcon(isTracking, icon);
  }

  Widget selectIcon(bool isTracking, Icon icon) {
    if (isTracking) {
      return FadeTransition(opacity: _controller, child: icon);
    }
    return icon;
  }

  Color selectColor(bool isTracking, bool isServiceDisabled, ColorScheme cs) {
    if (isTracking) {
      return cs.onPrimary;
    }
    if (isServiceDisabled) {
      return cs.error;
    }
    return cs.onSurfaceVariant;
  }
}
