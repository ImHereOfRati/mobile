import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iamhere/common/component/feedback/imhere_loading_indicator.dart';
import 'package:iamhere/feature/geofence/view_model/main/geofence_view_model.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
import 'package:iamhere/feature/user_permission/view/component/permission_guide_components.dart';
import 'package:permission_handler/permission_handler.dart';

/// 위치 권한 '항상 허용' 설정을 사용자에게 단계별로 안내하는 화면.
///
/// 지오펜스 활성화 전, 또는 메인 화면의 권한 경고 배너에서 진입한다.
/// 결과는 [Navigator.pop] 의 값으로 반환되며, `true` 는 '항상 허용' 획득을 의미한다.
class LocationPermissionGuideView extends ConsumerStatefulWidget {
  const LocationPermissionGuideView({super.key});

  @override
  ConsumerState<LocationPermissionGuideView> createState() =>
      _LocationPermissionGuideViewState();
}

class _LocationPermissionGuideViewState
    extends ConsumerState<LocationPermissionGuideView>
    with WidgetsBindingObserver {
  static const String _locationStepOneImage =
      'assets/images/location/location_setting_step_one.png';
  static const String _locationStepTwoImage =
      'assets/images/location/location_setting_step_two.png';
  static const String _locationStepThreeImage =
      'assets/images/location/location_setting_step_three.png';
  static const String _locationStepFourImage =
      'assets/images/location/location_setting_step_four.png';

  PermissionState? _currentStatus;
  bool _isProcessing = false;

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
    // 설정 앱에서 돌아왔을 때 권한 상태를 재확인한다.
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final service = ref.read(locationPermissionServiceProvider);
    final status = await service.checkPermissionStatus();
    if (!mounted) return;
    setState(() => _currentStatus = status);

    // '항상 허용' 이 확인되면 자동으로 true 반환하며 닫는다.
    if (status == PermissionState.grantedAlways) {
      ref.invalidate(geofenceViewModelProvider);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleAction() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final service = ref.read(locationPermissionServiceProvider);
    final status = _currentStatus ?? await service.checkPermissionStatus();

    try {
      if (status == PermissionState.serviceDisabled) {
        await Geolocator.openLocationSettings();
      } else if (status == PermissionState.permanentlyDenied ||
          status == PermissionState.grantedWhenInUse) {
        // 시스템 대화상자로 더 이상 상향 요청이 불가능한 상태 → 설정 앱으로 유도.
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
        title: const Text('위치 권한 안내'),
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
                        icon: Icons.my_location,
                        title: '위치 권한이 필요해요',
                        description: '앱이 닫혀 있어도 알림을 받으려면\n"항상 허용" 이 필요합니다.',
                      ),
                      SizedBox(height: 20.h),
                      _buildCurrentStatusCard(status, colorScheme),
                      SizedBox(height: 24.h),
                      _buildSectionTitle('왜 "항상 허용" 이 필요한가요?'),
                      SizedBox(height: 8.h),
                      _buildReasonText(colorScheme),
                      SizedBox(height: 24.h),
                      _buildSectionTitle('설정 방법'),
                      SizedBox(height: 12.h),
                      ..._buildSteps(status, colorScheme),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              _buildActionButton(status, colorScheme),
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
    final (label, color, icon) = _statusPresentation(status, colorScheme);
    return PermissionStatusBadge(label: label, color: color, icon: icon);
  }

  (String, Color, IconData) _statusPresentation(
    PermissionState? status,
    ColorScheme colorScheme,
  ) {
    if (status == null) {
      return ('확인 중...', colorScheme.onSurface, Icons.hourglass_empty);
    }

    return {
          PermissionState.serviceDisabled: (
            'GPS 꺼짐',
            colorScheme.error,
            Icons.location_off,
          ),
          PermissionState.grantedAlways: (
            '항상 허용',
            colorScheme.primary,
            Icons.check_circle,
          ),
          PermissionState.grantedWhenInUse: (
            '앱 사용 중에만 허용',
            colorScheme.tertiary,
            Icons.info,
          ),
          PermissionState.denied: ('거부됨', colorScheme.error, Icons.cancel),
          PermissionState.permanentlyDenied: (
            '영구 거부됨',
            colorScheme.error,
            Icons.block,
          ),
          PermissionState.restricted: ('제한됨', colorScheme.error, Icons.lock),
        }[status] ??
        ('알 수 없음', colorScheme.onSurface, Icons.help_outline);
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildReasonText(ColorScheme colorScheme) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '도착 메시지가 누락 없이 안전하게 전송되도록 위치 설정이 필요해요.\n\n',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const TextSpan(
            text: '등록한 장소에 정확하게 반응하려면 스마트폰의 위치 서비스(GPS)가 항상 켜져 있어야 합니다.\n\n',
          ),
          TextSpan(
            text: '"앱 사용 중에만 허용" 상태인 경우, ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
          const TextSpan(
            text: '앱을 완전히 종료했을 때 알림 메시지가 친구에게 전송되지 않을 수 있어요. 아래 가이드를 참고하여 ',
          ),
          TextSpan(
            text: '"항상 허용"으로 변경',
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
    );
  }

  List<Widget> _buildSteps(PermissionState? status, ColorScheme colorScheme) {
    final needsInitialRequest =
        status == PermissionState.denied || status == null;

    return [
      PermissionStepTile(
        number: 1,
        title: status == PermissionState.serviceDisabled
            ? '위치 설정 화면을 열어주세요'
            : needsInitialRequest
            ? '권한 요청을 시작해주세요'
            : '시스템 설정 화면으로 이동합니다',
        description: needsInitialRequest
            ? '시스템 팝업이 나타나면 먼저 "앱 사용 중에만 허용" 을 선택해주세요. 선택 후 하단의 "설정 앱에서 변경하기" 버튼을 눌러주시면 됩니다.'
            : status == PermissionState.serviceDisabled
            ? '위치 서비스가 꺼져 있으면 먼저 기기 설정에서 위치를 켜 주세요.'
            : '2단계를 설정을 위해 아래의 \n"설정 앱에서 변경하기" 버튼을 클릭하세요',
        imagePath: _locationStepOneImage,
      ),
      SizedBox(height: 10.h),
      PermissionStepTile(
        number: 2,
        title: '설정 화면에서 "권한" 선택',
        description: '이동한 기기 설정 화면에서 "권한" 메뉴를 탭해 주세요.',
        imagePath: _locationStepTwoImage,
      ),
      SizedBox(height: 10.h),
      PermissionStepTile(
        number: 3,
        title: '앱 권한 목록에서 "위치" 선택',
        description: '권한 목록 화면에서 "위치" 설정 메뉴를 탭해 주세요.',
        imagePath: _locationStepThreeImage,
      ),
      SizedBox(height: 10.h),
      PermissionStepTile(
        number: 4,
        title: '"항상 허용" 및 정확한 위치 활성화',
        description:
            '위치 권한 화면에서 "항상 허용"을 선택해 주세요.\n'
            '아래의 "정확한 위치 사용" 토글도 켜 주시면 도착 감지가 훨씬 안정적이에요.',
        imagePath: _locationStepFourImage,
      ),
    ];
  }

  Widget _buildActionButton(PermissionState? status, ColorScheme colorScheme) {
    final Map<PermissionState, String> labels = {
      PermissionState.serviceDisabled: '위치 서비스(GPS) 켜기',
      PermissionState.grantedWhenInUse: '설정 앱에서 변경하기',
      PermissionState.permanentlyDenied: '설정 앱에서 변경하기',
      PermissionState.restricted: '설정 앱 열기',
    };

    final label = labels[status] ?? '권한 요청 시작하기';

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
