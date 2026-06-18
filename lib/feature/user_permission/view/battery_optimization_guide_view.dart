import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/feature/user_permission/view/component/permission_guide_components.dart';
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
  bool _shouldCloseOnGranted = false;
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

    if (status == PermissionState.grantedAlways && _shouldCloseOnGranted && !_popped) {
      ref.invalidate(batteryOptimizationStatusProvider);
      _popped = true;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleAction() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _shouldCloseOnGranted = true;

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
                      PermissionGuideHeader(
                        icon: Icons.battery_saver,
                        title: '배터리 최적화 제외가 필요해요',
                        description: Platform.isAndroid
                            ? '스마트폰 화면이 꺼져 있어도 도착 알림이\n누락 없이 안전하게 전송되도록 설정합니다.'
                            : 'iOS 는 별도 설정이 필요하지 않습니다.',
                      ),
                      SizedBox(height: 20.h),
                      _buildCurrentStatusCard(status, colorScheme),
                      SizedBox(height: 24.h),
                      _buildWhySection(colorScheme),
                      SizedBox(height: 24.h),
                      _buildStepsSection(status),
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

  Widget _buildCurrentStatusCard(
    PermissionState? status,
    ColorScheme colorScheme,
  ) {
    final (label, color, icon) = switch (status) {
      PermissionState.grantedAlways => (
        '제외 완료',
        colorScheme.primary,
        Icons.check_circle,
      ),
      PermissionState.denied => ('미적용', colorScheme.error, Icons.cancel),
      PermissionState.permanentlyDenied => (
        '시스템에서 거부됨',
        colorScheme.error,
        Icons.block,
      ),
      PermissionState.restricted => ('제한됨', colorScheme.error, Icons.lock),
      PermissionState.grantedWhenInUse ||
      PermissionState.serviceDisabled ||
      null => ('확인 중...', colorScheme.onSurface, Icons.hourglass_empty),
    };
    return PermissionStatusBadge(label: label, color: color, icon: icon);
  }

  Widget _buildWhySection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '왜 필요한가요?',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '도착/출발 메시지가 늦게 전송되거나 누락되는 것을 방지하기 위해 설정이 필요해요.\n\n',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const TextSpan(
                text: '스마트폰은 배터리를 아끼기 위해 사용하지 않는 앱을 잠시 멈추는 기능을 가지고 있어요.\n\n',
              ),
              const TextSpan(
                text: '지정한 장소에 도착했을 때 친구에게 메시지가 누락 없이 바로 전송될 수 있도록, 아래 버튼을 눌러 ',
              ),
              TextSpan(
                text: '"배터리 최적화 대상에서 제외"',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const TextSpan(text: '해 주세요!'),
            ],
          ),
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.6,
            color: colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection(PermissionState? status) {
    final isPermanentlyDenied = status == PermissionState.permanentlyDenied;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '설정 방법',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12.h),
        PermissionStepTile(
          number: 1,
          title: isPermanentlyDenied ? '설정 앱으로 이동합니다' : '"허용" 을 선택해주세요',
          description: isPermanentlyDenied
              ? '앱 정보 > 배터리 메뉴에서 "제한 없음" 또는 "최적화 안 함" 을 선택해 주세요.'
              : '아래와 같은 시스템 팝업이 나타나면 "허용" 을 선택해 주세요.',
          imagePath: 'assets/images/battery_step.png',
        ),
      ],
    );
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
            ? const ImHereLoadingIndicator(height: 18)
            : Text(
                label,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
