import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/geofence/view_model/list/geofence_list_view_model.dart';
import 'package:iamhere/feature/geofence/view_model/main/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/shared/component/view_component/page_title.dart';

import 'geofence_warning_banner.dart';
import 'gps_status_card.dart';

const String _mainTitle = '내 위치 기반 알림';
const String _mainDescription = '특정 위치에 도착하면 친구에게 자동으로 메시지를 보냅니다';
const String _registeredCount = '개 등록됨';
const String _loading = '로딩 중...';
const String _error = '오류';
const String _warningServiceDisabled = '기기의 GPS(위치 서비스)가 꺼져 있습니다';
const String _warningAlwaysLocation = '항상 허용으로 위치를 설정해주셔야 앱이 정상 작동합니다';
const String _warningBatteryOptimization =
    '앱이 꺼진 상태에서 알림을 보내기 위해 배터리 최적화 제외가 필요해요';

class GeofenceHeader extends ConsumerWidget {
  final PermissionState permissionStatus;
  final bool isBatteryOptimizationMissing;

  const GeofenceHeader({
    super.key,
    required this.permissionStatus,
    required this.isBatteryOptimizationMissing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofencesAsyncValue = ref.watch(geofenceListViewModelProvider);
    final isAlwaysLocationMissing =
        permissionStatus != PermissionState.grantedAlways;

    return PageTitle(
      title: _mainTitle,
      description: _mainDescription,
      infoCount: geofencesAsyncValue.when(
        data: (g) => "${g.length}$_registeredCount",
        loading: () => _loading,
        error: (_, __) => _error,
      ),
      bottomSpacing: 12.h,
      actions: [
        const GPSStatusCard(),
        if (isAlwaysLocationMissing) ...[
          SizedBox(height: 8.h),
          GeofenceWarningBanner(
            icon: permissionStatus == PermissionState.serviceDisabled
                ? Icons.location_off_rounded
                : Icons.warning_amber_rounded,
            text: permissionStatus == PermissionState.serviceDisabled
                ? _warningServiceDisabled
                : _warningAlwaysLocation,
            color: Theme.of(context).colorScheme.errorContainer,
            onTap: () async {
              if (await AppRoutes.pushLocationPermissionGuide(context)) {
                ref.invalidate(geofenceViewModelProvider);
              }
            },
          ),
        ],
        if (isBatteryOptimizationMissing) ...[
          SizedBox(height: 8.h),
          GeofenceWarningBanner(
            icon: Icons.battery_saver,
            text: _warningBatteryOptimization,
            color: Theme.of(context).colorScheme.errorContainer,
            onTap: () async {
              if (await AppRoutes.pushBatteryOptimizationGuide(context)) {
                ref.invalidate(batteryOptimizationStatusProvider);
              }
            },
          ),
        ],
      ],
    );
  }
}
