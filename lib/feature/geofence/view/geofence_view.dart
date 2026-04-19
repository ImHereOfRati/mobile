import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/core/di/di_setup.dart';
import 'package:iamhere/feature/geofence/repository/geofence_entity.dart';
import 'package:iamhere/feature/geofence/service/geocoding_service.dart';
import 'package:iamhere/feature/geofence/service/native_geofence_registrar_interface.dart';
import 'package:iamhere/feature/geofence/view_model/geofence_list_view_model.dart';
import 'package:iamhere/feature/geofence/view_model/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
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
          ),
          interval: 2,
        ),

        // 2. 지오펜스 타일 목록
        Expanded(
          flex: 5,
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
  ) {
    return permissionAsyncValue.when(
      data: (permissionStatus) => Container(
        // 높이를 40px 기준으로 반응형 설정
        height: 40.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.all(
            // radius를 20px 기준으로 반응형 설정
            Radius.circular(20.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [_buildBlinkingGPSIcon(), _buildDescription()],
        ),
      ),
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
  Widget _buildDescription() {
    final descriptionMessageWhenPermissionGood = "위치 추적 중이에요";
    return Text(
      descriptionMessageWhenPermissionGood,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16.sp,
      ),
    );
  }

  // 깜빡이는 GPS 아이콘 (ScreenUtil 적용)
  FadeTransition _buildBlinkingGPSIcon() {
    return FadeTransition(
      opacity: _controller,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 4.w, 0),
        child: Icon(Icons.location_on_outlined, color: Colors.red, size: 25.sp),
      ),
    );
  }
}
