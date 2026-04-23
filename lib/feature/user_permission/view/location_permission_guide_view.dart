import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iamhere/feature/user_permission/model/permission_state.dart';
import 'package:iamhere/feature/user_permission/service/permission_service_provider.dart';
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
                      _buildHeader(colorScheme),
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
            Icons.my_location,
            color: colorScheme.onPrimaryContainer,
            size: 36.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '위치 권한이 필요해요',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '앱이 닫혀 있어도 알림을 받으려면\n"항상 허용" 이 필요합니다.',
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
    if (status == null) {
      return ('확인 중...', colorScheme.onSurface, Icons.hourglass_empty);
    }

    return {
          PermissionState.serviceDisabled: (
            'GPS 꺼짐',
            colorScheme.error,
            Icons.location_off
          ),
          PermissionState.grantedAlways: ('항상 허용', Colors.green, Icons.check_circle),
          PermissionState.grantedWhenInUse:
              ('앱 사용 중에만 허용', Colors.orange, Icons.info),
          PermissionState.denied: ('거부됨', colorScheme.error, Icons.cancel),
          PermissionState.permanentlyDenied:
              ('영구 거부됨', colorScheme.error, Icons.block),
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
    return Text(
      '등록한 장소에 도착했을 때 친구에게 자동으로 메시지를 보내려면\n'
      '기기의 GPS(위치 서비스)가 켜져 있어야 하며,\n'
      '앱이 백그라운드나 종료 상태에서도 위치를 확인할 수 있어야 합니다.\n\n'
      '"앱 사용 중에만 허용" 상태에서는 앱을 종료하면 알림이 동작하지 않아요.',
      style: TextStyle(
        fontSize: 14.sp,
        height: 1.5,
        color: colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }

  List<Widget> _buildSteps(PermissionState? status, ColorScheme colorScheme) {
    if (status == PermissionState.serviceDisabled) {
      return [
        _StepTile(
          number: 1,
          title: '기기 위치 서비스(GPS) 켜기',
          description: '아래 버튼을 눌러 시스템 설정에서 위치 서비스를 활성화해주세요.',
        ),
        SizedBox(height: 10.h),
        _StepTile(
          number: 2,
          title: '앱으로 돌아오기',
          description: 'GPS를 켠 후 앱으로 돌아오면 다음 단계를 안내해 드립니다.',
        ),
      ];
    }

    final needsInitialRequest =
        status == PermissionState.denied || status == null;

    return [
      _StepTile(
        number: 1,
        title: needsInitialRequest
            ? '아래 버튼을 눌러 권한 요청을 시작해주세요'
            : '시스템 설정 화면으로 이동합니다',
        description: needsInitialRequest
            ? '시스템 팝업이 나타나면 먼저 "앱 사용 중에만 허용" 을 선택해주세요.'
            : '앱 정보 > 권한 > 위치 메뉴로 이동합니다.',
      ),
      SizedBox(height: 10.h),
      _StepTile(
        number: 2,
        title: '"항상 허용" 으로 변경',
        description:
            '위치 권한 화면에서 "항상 허용" 을 선택해주세요.\n'
            '(Android 11+ 또는 iOS 에서는 별도 화면에서 선택해야 할 수 있어요.)',
      ),
      SizedBox(height: 10.h),
      _StepTile(
        number: 3,
        title: '앱으로 돌아오기',
        description: '설정을 마치면 앱으로 돌아와 주세요. 자동으로 권한 상태를 확인합니다.',
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
