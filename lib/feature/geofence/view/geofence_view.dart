import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/core/router/app_routes.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/geocoding_service.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/geofence/view_model/geofence_list_view_model.dart';
import 'package:iamhere/feature/geofence/view_model/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/shared/component/view_component/widgets/page_title.dart';

import 'widget/geofence_tile.dart';

class GeofenceView extends ConsumerStatefulWidget {
  const GeofenceView({super.key});

  @override
  ConsumerState<GeofenceView> createState() => _GeofenceViewState();
}

class _GeofenceViewState extends ConsumerState<GeofenceView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _geocodingService = GeocodingService();
  final Map<int, String> _addressCache = {};

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

  /// 활성 지오펜스 목록을 OS 에 재동기화한다.
  /// OS 네이티브 geofence 는 백그라운드/프로세스 종료 상태에서도 동작하므로,
  /// Dart 측 연속 모니터링은 더 이상 필요하지 않다.
  Future<void> _syncGeofencesWithOs(List<GeofenceEntity> geofences) async {
    try {
      final registrar = getIt<NativeGeofenceRegistrarInterface>();
      final active = geofences.where((g) => g.isActive).toList();
      await registrar.syncAll(active);
    } catch (e) {
      debugPrint('OS 지오펜스 동기화 실패: $e');
    }
  }

  void _handleToggle(GeofenceEntity geofence, bool newValue) async {
    if (geofence.id == null) return;

    // 활성화 시에는 반드시 위치 권한 '항상 허용' 이 필요하다.
    // OS 네이티브 지오펜스가 앱이 종료된 상태에서도 동작하려면
    // `locationAlways` 권한이 요구된다.
    if (newValue) {
      final granted = await _ensureAlwaysLocationPermission();
      if (!granted) return;
    }

    try {
      final listViewModel = ref.read(geofenceListViewModelProvider.notifier);
      await listViewModel.toggleActive(geofence.id!, newValue);

      // 토글 후 목록을 OS 와 재동기화 (iOS 20개 제한 등 정책 적용).
      final geofencesAsyncValue = ref.read(geofenceListViewModelProvider);
      geofencesAsyncValue.whenData((geofences) {
        _syncGeofencesWithOs(geofences);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('활성화 상태 변경 실패: ${e.toString()}')),
        );
      }
    }
  }

  /// 지오펜스 활성화 전에 위치 권한 '항상 허용' 을 확인/요청한다.
  /// 이미 허용된 경우 즉시 true. 그 외에는 가이드 화면으로 이동시킨다.
  Future<bool> _ensureAlwaysLocationPermission() async {
    final permissionService = ref.read(locationPermissionServiceProvider);
    final current = await permissionService.checkPermissionStatus();
    if (current == PermissionState.grantedAlways) return true;
    if (!mounted) return false;

    return await AppRoutes.pushLocationPermissionGuide(context);
  }

  Future<void> _handleDelete(GeofenceEntity geofence) async {
    if (geofence.id == null) return;

    // 삭제 확인 다이얼로그 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지오펜스 삭제'),
        content: Text('${geofence.name} 지오펜스를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final listViewModel = ref.read(geofenceListViewModelProvider.notifier);
      await listViewModel.delete(geofence.id!);

      // 삭제 후 OS 와 재동기화.
      final geofencesAsyncValue = ref.read(geofenceListViewModelProvider);
      geofencesAsyncValue.whenData((geofences) {
        _syncGeofencesWithOs(geofences);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${geofence.name} 지오펜스가 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: ${e.toString()}')));
      }
    }
  }

  // 연락처 ID 리스트에서 개수 가져오기
  int _getMemberCount(String contactIdsJson) {
    try {
      final List<dynamic> contactIds = jsonDecode(contactIdsJson);
      return contactIds.length;
    } catch (e) {
      return 0;
    }
  }

  /// 지오펜스 목록의 주소를 일괄 resolve (캐시에 없는 것만)
  final Set<int> _pendingIds = {};

  void _resolveAddresses(List<GeofenceEntity> geofences) {
    for (final geofence in geofences) {
      final id = geofence.id ?? -1;
      if (_addressCache.containsKey(id) || _pendingIds.contains(id)) continue;

      _pendingIds.add(id);
      _geocodingService.reverseGeocode(geofence.lat, geofence.lng).then((addr) {
        if (mounted) {
          setState(() {
            _addressCache[id] = addr;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final geofencesAsyncValue = ref.watch(geofenceListViewModelProvider);
    final permissionAsyncValue = ref.watch(geofenceViewModelProvider);

    final pageTitle = "내 위치 기반 알림";
    final pageDescription = "특정 위치에 도착하면 친구에게 자동으로 메시지를 보냅니다";

    // '항상 허용' 이 아니거나 배터리 최적화가 제외되지 않았을 때 경고 배너가 추가로 렌더된다.
    // 타이틀 영역의 flex 비중을 높여 오버플로우를 방지한다.
    final batteryAsyncValue = ref.watch(batteryOptimizationStatusProvider);
    final needsLocationWarning = permissionAsyncValue.maybeWhen(
      data: (status) => status != PermissionState.grantedAlways,
      orElse: () => false,
    );
    final needsBatteryWarning = batteryAsyncValue.maybeWhen(
      data: (status) => status != PermissionState.grantedAlways,
      orElse: () => false,
    );
    final needsWarning = needsLocationWarning || needsBatteryWarning;
    final titleFlex = needsWarning ? 3 : 2;
    final listFlex = needsWarning ? 6 : 5;

    return Column(
      children: [
        // 1. 페이지 타이틀 (추가 위젯 포함)
        PageTitle(
          key: ValueKey(pageTitle),
          pageTitle: pageTitle,
          pageDescription: pageDescription,
          pageInfoCount: geofencesAsyncValue.when(
            data: (geofences) => "${geofences.length}개 등록됨",
            loading: () => "로딩 중...",
            error: (_, __) => "오류",
          ),
          additionalWidget: _buildGPSInfoTrackingUsingDescription(
            permissionAsyncValue,
            geofencesAsyncValue,
          ),
          interval: 2,
          expandedWidgetFlex: titleFlex,
        ),

        // 2. 지오펜스 타일 목록
        Expanded(
          flex: listFlex,
          child: geofencesAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      '지오펜스 로드 실패',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.55),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(geofenceListViewModelProvider.notifier)
                            .refresh();
                      },
                      child: Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
            data: (geofences) {
              // 목록 로드 시마다 OS 등록 상태 재동기화.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncGeofencesWithOs(geofences);
                _resolveAddresses(geofences);
              });

              if (geofences.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '등록된 지오펜스가 없습니다',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '지오펜스를 등록해주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                itemCount: geofences.length,
                itemBuilder: (context, index) {
                  final geofence = geofences[index];
                  final memberCount = _getMemberCount(geofence.contactIds);
                  final address =
                      _addressCache[geofence.id ?? -1] ?? '주소 불러오는 중...';

                  return GeofenceTile(
                    key: ValueKey(geofence.id),
                    homeName: geofence.name,
                    address: address,
                    memberCount: memberCount,
                    isToggleOn: geofence.isActive,
                    onToggleChanged: (newValue) =>
                        _handleToggle(geofence, newValue),
                    onLongPress: () => _handleDelete(geofence),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // GPS 추적 정보 표시 위젯 (ScreenUtil 적용)
  Widget _buildGPSInfoTrackingUsingDescription(
    AsyncValue<PermissionState> permissionAsyncValue,
    AsyncValue<List<GeofenceEntity>> geofencesAsyncValue,
  ) {
    return permissionAsyncValue.when(
      data: (permissionStatus) {
        final isAlwaysGranted =
            permissionStatus == PermissionState.grantedAlways;
        final hasActiveGeofence = geofencesAsyncValue.maybeWhen(
          data: (geofences) => geofences.any((g) => g.isActive),
          orElse: () => false,
        );
        final isTracking = isAlwaysGranted && hasActiveGeofence;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 40.h,
              decoration: BoxDecoration(
                color: isTracking
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.all(Radius.circular(20.r)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildGPSIcon(isTracking),
                  _buildDescription(isTracking),
                ],
              ),
            ),
            if (!isAlwaysGranted) ...[
              SizedBox(height: 6.h),
              _buildAlwaysPermissionWarning(),
            ],
            // 위치 권한과는 독립적으로 배터리 최적화 제외 여부를 검사한다.
            // 둘 다 종료 상태 알람 안정성에 필수이므로 나란히 노출.
            ..._buildBatteryOptimizationWarningIfNeeded(),
          ],
        );
      },
      loading: () => SizedBox(
        height: 40.h,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SizedBox(
        height: 40.h,
        child: Center(child: Text('권한 상태 확인 실패')),
      ),
    );
  }

  // 위치 추적 설명 텍스트 (ScreenUtil 적용)
  Widget _buildDescription(bool isTracking) {
    final message = isTracking ? "위치 추적 중이에요" : "위치 추적을 하고 있지 않아요";
    return Text(
      message,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: isTracking
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        fontSize: 16.sp,
      ),
    );
  }

  // GPS 아이콘 — 추적 중엔 깜빡이고, 아닐 땐 정적으로 표시한다.
  Widget _buildGPSIcon(bool isTracking) {
    final icon = Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 4.w, 0),
      child: Icon(
        Icons.location_on_outlined,
        color: isTracking
            ? Colors.red
            : Theme.of(context).colorScheme.onSurfaceVariant,
        size: 25.sp,
      ),
    );
    if (!isTracking) return icon;
    return FadeTransition(opacity: _controller, child: icon);
  }

  List<Widget> _buildBatteryOptimizationWarningIfNeeded() {
    final batteryAsyncValue = ref.watch(batteryOptimizationStatusProvider);
    return batteryAsyncValue.maybeWhen(
      data: (status) {
        if (status == PermissionState.grantedAlways) return const <Widget>[];
        return [SizedBox(height: 6.h), _buildBatteryOptimizationWarning()];
      },
      orElse: () => const <Widget>[],
    );
  }

  Widget _buildBatteryOptimizationWarning() {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
        onTap: () async {
          final granted = await AppRoutes.pushBatteryOptimizationGuide(context);
          if (!mounted) return;
          // 상태 갱신 — granted 여부와 무관하게 최신 상태로 반영.
          ref.invalidate(batteryOptimizationStatusProvider);
          if (granted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('배터리 최적화 제외가 적용되었습니다.')),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.all(Radius.circular(12.r)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.battery_saver,
                color: colorScheme.onTertiaryContainer,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '배터리 최적화 제외가 필요해요. 앱이 꺼진 상태에서 알림이 놓쳐질 수 있어요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onTertiaryContainer,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // '항상 허용' 권한이 아닐 때 노출되는 경고 문구. 탭하면 가이드 화면으로 이동한다.
  Widget _buildAlwaysPermissionWarning() {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
        onTap: () async {
          final granted = await AppRoutes.pushLocationPermissionGuide(context);
          if (!mounted) return;
          if (granted) {
            ref.invalidate(geofenceViewModelProvider);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.all(Radius.circular(12.r)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.onErrorContainer,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '항상 허용으로 위치를 설정해주셔야 앱이 정상으로 작동됩니다',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onErrorContainer,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
