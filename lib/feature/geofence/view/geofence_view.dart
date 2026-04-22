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
import 'package:iamhere/shared/component/view_component/page_title.dart';

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
  final Set<int> _pendingIds = {};

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

  // ── 비즈니스 로직 (기존 유지) ──────────────────────────────────────────

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
    if (newValue) {
      final granted = await _ensureAlwaysLocationPermission();
      if (!granted) return;
    }
    try {
      final listViewModel = ref.read(geofenceListViewModelProvider.notifier);
      await listViewModel.toggleActive(geofence.id!, newValue);
      ref
          .read(geofenceListViewModelProvider)
          .whenData((g) => _syncGeofencesWithOs(g));
    } catch (e) {
      if (mounted) _showSnackBar('활성화 상태 변경 실패: $e');
    }
  }

  Future<bool> _ensureAlwaysLocationPermission() async {
    final permissionService = ref.read(locationPermissionServiceProvider);
    final current = await permissionService.checkPermissionStatus();
    if (current == PermissionState.grantedAlways) return true;
    if (!mounted) return false;
    return await AppRoutes.pushLocationPermissionGuide(context);
  }

  Future<void> _handleDelete(GeofenceEntity geofence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지오펜스 삭제'),
        content: Text('${geofence.name} 지오펜스를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(geofenceListViewModelProvider.notifier).delete(geofence.id!);
    ref
        .read(geofenceListViewModelProvider)
        .whenData((g) => _syncGeofencesWithOs(g));
  }

  void _resolveAddresses(List<GeofenceEntity> geofences) {
    for (final g in geofences) {
      final id = g.id ?? -1;
      if (_addressCache.containsKey(id) || _pendingIds.contains(id)) continue;
      _pendingIds.add(id);
      _geocodingService.reverseGeocode(g.lat, g.lng).then((addr) {
        if (mounted) setState(() => _addressCache[id] = addr);
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ── UI 빌드 ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final geofencesAsyncValue = ref.watch(geofenceListViewModelProvider);
    final permissionAsyncValue = ref.watch(geofenceViewModelProvider);
    final batteryAsyncValue = ref.watch(batteryOptimizationStatusProvider);

    // 권한 및 상태 체크
    final isAlwaysLocationMissing = permissionAsyncValue.maybeWhen(
      data: (status) => status != PermissionState.grantedAlways,
      orElse: () => false,
    );
    final isBatteryOptimizationMissing = batteryAsyncValue.maybeWhen(
      data: (status) => status != PermissionState.grantedAlways,
      orElse: () => false,
    );

    return Column(
      children: [
        // 1. 타이틀 영역 (개선된 PageTitle 사용)
        Expanded(
          flex: (isAlwaysLocationMissing || isBatteryOptimizationMissing)
              ? 4
              : 3,
          child: PageTitle(
            title: "내 위치 기반 알림",
            description: "특정 위치에 도착하면 친구에게 자동으로 메시지를 보냅니다",
            infoCount: geofencesAsyncValue.when(
              data: (g) => "${g.length}개 등록됨",
              loading: () => "로딩 중...",
              error: (_, __) => "오류",
            ),
            bottomSpacing: 12.h,
            actions: [
              // GPS 상태 카드
              _buildGPSStatusCard(permissionAsyncValue, geofencesAsyncValue),

              // 경고 배너들 (조건부 노출)
              if (isAlwaysLocationMissing) ...[
                SizedBox(height: 8.h),
                _buildWarningBanner(
                  icon: Icons.warning_amber_rounded,
                  text: '항상 허용으로 위치를 설정해주셔야 앱이 정상 작동합니다',
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
                _buildWarningBanner(
                  icon: Icons.battery_saver,
                  text: '앱이 꺼진 상태에서 알림을 보내기 위해 배터리 최적화 제외가 필요해요',
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  onTap: () async {
                    if (await AppRoutes.pushBatteryOptimizationGuide(context)) {
                      ref.invalidate(batteryOptimizationStatusProvider);
                    }
                  },
                ),
              ],
            ],
          ),
        ),

        // 2. 리스트 영역
        Expanded(
          flex: 6,
          child: geofencesAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _buildErrorView(err.toString()),
            data: (geofences) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncGeofencesWithOs(geofences);
                _resolveAddresses(geofences);
              });

              if (geofences.isEmpty) return _buildEmptyView();

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                itemCount: geofences.length,
                itemBuilder: (context, index) {
                  final g = geofences[index];
                  return GeofenceTile(
                    key: ValueKey(g.id),
                    homeName: g.name,
                    address: _addressCache[g.id ?? -1] ?? '주소 불러오는 중...',
                    memberCount: _getMemberCount(g.contactIds),
                    isToggleOn: g.isActive,
                    onToggleChanged: (val) => _handleToggle(g, val),
                    onLongPress: () => _handleDelete(g),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 소형 위젯 분리 ─────────────────────────────────────────────────────

  Widget _buildGPSStatusCard(
    AsyncValue<PermissionState> pAsync,
    AsyncValue<List<GeofenceEntity>> gAsync,
  ) {
    return pAsync.maybeWhen(
      data: (status) {
        final isTracking =
            (status == PermissionState.grantedAlways) &&
            gAsync.maybeWhen(
              data: (g) => g.any((item) => item.isActive),
              orElse: () => false,
            );

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isTracking
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              _buildGPSIcon(isTracking),
              SizedBox(width: 8.w),
              Text(
                isTracking ? "위치 추적 중이에요" : "위치 추적을 하고 있지 않아요",
                style: TextStyle(
                  color: isTracking
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildGPSIcon(bool isTracking) {
    final icon = Icon(
      Icons.location_on_outlined,
      color: isTracking
          ? Colors.redAccent
          : Theme.of(context).colorScheme.onSurfaceVariant,
      size: 20.sp,
    );
    return isTracking
        ? FadeTransition(opacity: _controller, child: icon)
        : icon;
  }

  Widget _buildWarningBanner({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(icon, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() => Center(
    child: Text(
      '등록된 지오펜스가 없습니다',
      style: TextStyle(fontSize: 16.sp, color: Colors.grey),
    ),
  );

  Widget _buildErrorView(String msg) => Center(child: Text('오류 발생: $msg'));

  int _getMemberCount(String json) {
    try {
      return (jsonDecode(json) as List).length;
    } catch (_) {
      return 0;
    }
  }
}
