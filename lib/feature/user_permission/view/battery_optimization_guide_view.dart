import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 배터리 최적화 제외 설정을 사용자에게 안내하는 화면 (Android 전용).
///
/// Doze / App Standby 로 인해 지오펜스 백그라운드 콜백 중 SMS/FCM API 호출이
/// 도중에 kill 될 수 있다. 이 화면은 사용자에게 앱을 배터리 최적화 대상에서
/// 제외하도록 요청한다.
///
/// 결과는 [Navigator.pop] 의 값으로 반환되며 `true` 는 제외 완료를 의미한다.
class BatteryOptimizationGuideView extends ConsumerStatefulWidget {
  const BatteryOptimizationGuideView({super.key});

  @override
  ConsumerState<BatteryOptimizationGuideView> createState() =>
      _BatteryOptimizationGuideViewState();
}

class _BatteryOptimizationGuideViewState
    extends ConsumerState<BatteryOptimizationGuideView>
    with WidgetsBindingObserver {
  PermissionState? _currentStatus;
  bool _isProcessing = false;
  // 배터리 최적화 시스템 다이얼로그는 인앱 오버레이라 `resumed` 와 `_handleAction.finally`
  // 가 거의 동시에 _refreshStatus 를 호출한다. 두 경로가 모두 status=grantedAlways 를
  // 보고 pop 하면 두 번째 pop 에서 go_router 의 currentConfiguration.isNotEmpty
  // 어설션이 터진다. 이 플래그로 단일 pop 을 보장한다.
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final service = ref.read(batteryOptimizationPermissionServiceProvider);
    final status = await service.checkPermissionStatus();
    if (!mounted) return;
    setState(() => _currentStatus = status);

    if (status == PermissionState.grantedAlways && !_popped) {
      _popped = true;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleAction() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final service = ref.read(batteryOptimizationPermissionServiceProvider);
    final status = _currentStatus ?? await service.checkPermissionStatus();

    try {
      if (status == PermissionState.permanentlyDenied) {
        // 시스템 다이얼로그 재노출이 막힌 경우 설정 앱으로 유도.
        await openAppSettings();
      } else {
        await service.requestPermission();
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        await _refreshStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = _currentStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('배터리 최적화 제외 안내'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(colorScheme),
                      SizedBox(height: 20.h),
                      _buildCurrentStatusCard(status, colorScheme),
                      SizedBox(height: 24.h),
                      _buildSectionTitle('왜 필요한가요?'),
                      SizedBox(height: 8.h),
                      _buildReasonText(colorScheme),
                      SizedBox(height: 24.h),
                      _buildSectionTitle('설정 방법'),
                      SizedBox(height: 12.h),
                      ..._buildSteps(status),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              _buildActionButton(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.battery_saver,
            color: colorScheme.onPrimaryContainer,
            size: 36.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '배터리 최적화 제외가 필요해요',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  Platform.isAndroid
                      ? '앱이 꺼져 있을 때 도착 알림이\n놓쳐지지 않도록 설정이 필요합니다.'
                      : 'iOS 는 별도 설정이 필요하지 않습니다.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard(
    PermissionState? status,
    ColorScheme colorScheme,
  ) {
    final (label, color, icon) = _statusPresentation(status, colorScheme);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            '현재 상태: ',
            style: TextStyle(
              fontSize: 13.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _statusPresentation(
    PermissionState? status,
    ColorScheme colorScheme,
  ) {
    switch (status) {
      case PermissionState.grantedAlways:
        return ('제외 완료', Colors.green, Icons.check_circle);
      case PermissionState.denied:
        return ('미적용', colorScheme.error, Icons.cancel);
      case PermissionState.permanentlyDenied:
        return ('시스템에서 거부됨', colorScheme.error, Icons.block);
      case PermissionState.restricted:
        return ('제한됨', colorScheme.error, Icons.lock);
      case PermissionState.grantedWhenInUse:
      case null:
        return ('확인 중...', colorScheme.onSurface, Icons.hourglass_empty);
    }
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildReasonText(ColorScheme colorScheme) {
    return Text(
      'Android 는 배터리 절약을 위해 일정 시간이 지난 앱의 백그라운드 실행을 제한합니다(Doze / App Standby).\n\n'
      '이 제한이 적용되면 도착 시 친구에게 메시지를 보내는 기능이 일부 환경에서 동작하지 않을 수 있어요.\n\n'
      '아래 버튼을 눌러 "배터리 최적화 제외" 목록에 이 앱을 추가해 주세요.',
      style: TextStyle(
        fontSize: 14.sp,
        height: 1.5,
        color: colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }

  List<Widget> _buildSteps(PermissionState? status) {
    final isPermanentlyDenied = status == PermissionState.permanentlyDenied;
    return [
      _StepTile(
        number: 1,
        title: isPermanentlyDenied
            ? '설정 앱으로 이동합니다'
            : '"허용" 을 선택해주세요',
        description: isPermanentlyDenied
            ? '앱 정보 > 배터리 메뉴에서 "제한 없음" 또는 "최적화 안 함" 을 선택해 주세요.'
            : '시스템 팝업이 나타나면 "허용" 을 선택해 주세요.',
      ),
      SizedBox(height: 10.h),
      _StepTile(
        number: 2,
        title: '앱으로 돌아오기',
        description: '설정을 마치면 앱으로 돌아와 주세요. 자동으로 상태를 확인합니다.',
      ),
    ];
  }

  Widget _buildActionButton(PermissionState? status) {
    if (!Platform.isAndroid) {
      return SizedBox(
        height: 52.h,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            '확인',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final label = switch (status) {
      PermissionState.permanentlyDenied => '설정 앱에서 변경하기',
      PermissionState.restricted => '설정 앱 열기',
      _ => '배터리 최적화 제외 요청',
    };

    return SizedBox(
      height: 52.h,
      child: FilledButton(
        onPressed: _isProcessing ? null : _handleAction,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        child: _isProcessing
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.45,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
